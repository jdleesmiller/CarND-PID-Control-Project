# frozen_string_literal: true

require 'csv'
require 'English'
require 'json'
require 'tmpdir'

require 'cross_entropy'

DISTANCE_WEIGHT = -1
TOTAL_ABSOLUTE_CTE_WEIGHT = 0

def run(*args, **options)
  Dir.mktmpdir do |tmp|
    out_pathname = File.join(tmp, 'out')
    err_pathname = File.join(tmp, 'err')
    options[:out] = out_pathname
    options[:err] = err_pathname
    options[:in] = '/dev/null'

    command = ['build/pid'] + args.map(&:to_s)
    Process.waitpid(Process.spawn(*command, **options))

    [
      $CHILD_STATUS.exitstatus,
      File.read(out_pathname),
      File.read(err_pathname)
    ]
  end
end

def run_and_log(csv, *params, max_runtime)
  status, out, _err = run(*params, max_runtime)
  if [0, 1].member?(status)
    crashed = status == 1
    stats = JSON.parse(out)
    csv << [
      *params,
      crashed,
      stats['runtime'], stats['distance'], stats['total_absolute_cte']
    ]
    DISTANCE_WEIGHT * stats['distance'] +
      TOTAL_ABSOLUTE_CTE_WEIGHT * stats['total_absolute_cte']
  else
    # The run failed.
    csv << params
    Float::INFINITY
  end
end

COLUMNS = %w(
  kp ki kd min_throttle max_throttle throttle_angle_threshold
  crashed runtime distance total_absolute_cte
).freeze

def grid(max_runtime)
  CSV(STDOUT) do |csv|
    csv << COLUMNS
    ks = (0..4).map { |k| k / 20.0 }
    ks.product(ks, ks).each do |kp, ki, kd|
      run_and_log(csv, kp, ki, kd, 0.3, max_runtime)
    end
  end
end

# grid(60)

def cross_entropy_search(max_runtime)
  # Our initial guess at the optimal solution.
  # This is just a guess, so we give it a large standard deviation.
  ks = NArray[-2, -2, -2, 0.0, 0.0]
  ks_stddev = NArray[0.5, 0.5, 0.5, 1.0, 1.0]

  # Set up the problem. These are the CEM parameters.
  problem = CrossEntropy::ContinuousProblem.new(ks, ks_stddev)
  problem.num_samples = 60
  problem.num_elite = 10
  problem.max_iters = 30

  CSV(STDOUT) do |csv|
    csv << COLUMNS

    # Objective function (to be minimized).
    problem.to_score_sample do |params|
      k = NMath.exp(params[0...3]).to_a
      throttle = (NArray[1, 1] / (1.0 + NMath.exp(-params[3...5]))).to_a
      throttle = [-throttle[0]] + throttle # fix min_throttle = -max_throttle
      run_and_log(csv, *k, *throttle, max_runtime)
    end

    # Do some smoothing when updating the parameters based on new samples.
    # This isn't strictly required, but I find it often helps convergence.
    # Log the results
    smooth = 0.2
    problem.to_update do |new_mean, new_stddev|
      STDERR.puts new_mean.inspect
      STDERR.puts new_stddev.inspect
      smooth_mean = smooth * new_mean + (1 - smooth) * problem.param_mean
      smooth_stddev = smooth * new_stddev + (1 - smooth) * problem.param_stddev
      [smooth_mean, smooth_stddev]
    end

    problem.solve
    STDERR.puts problem.param_mean.inspect
  end
end

# cross_entropy_search(90)

def twiddle(params, deltas, max_runtime, tolerance)
  param_indexes = 0...(params.size)
  CSV(STDOUT) do |csv|
    csv << COLUMNS
    best_score = run_and_log(csv, *params, max_runtime)
    while deltas.sum > tolerance
      param_indexes.each do |i|
        next if deltas[i].zero?
        params[i] += deltas[i]
        score = run_and_log(csv, *params, max_runtime)
        if score < best_score
          best_score = score
          deltas[i] *= 1.1
        else
          params[i] -= 2 * deltas[i]
          score = run_and_log(csv, *params, max_runtime)
          if score < best_score
            best_score = score
            deltas[i] *= 1.1
          else
            params[i] += deltas[i]
            deltas[i] *= 0.9
          end
        end
      end
    end
  end
end

# twiddle(
#   [0.1, 0.0025, 0.01, -0.3, 0.3, 0.0],
#   [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
#   90, 0.01
# )

def staged_twiddle(params, deltas, max_runtime, tolerance, delta_multiplier)
  throttle = params[4]
  throttle_step = deltas[4]
  deltas[3] = 0
  deltas[4] = 0

  loop do
    params[3] = -throttle
    params[4] = throttle
    twiddle(params, deltas, max_runtime, tolerance)

    STDERR.puts [throttle, params, deltas].inspect

    deltas = deltas.map { |delta| delta * delta_multiplier }
    throttle += throttle_step
    break if throttle > 1
  end
end

# staged_twiddle(
#   [0.0235, 0.0627, 0.1357, 0.0, 0.30, 0.1],
#   [0.0500, 0.0500, 0.0500, 0.0, 0.05, 0.1],
#   90, 0.005, 10
# )

def staged_cross_entropy(max_runtime)
  # Our initial guess at the optimal solution.
  # This is just a guess, so we give it a large standard deviation.
  ks = NMath.log(NArray[0.07, 0.001, 0.04])
  ks_stddev = NArray[0.1, 0.1, 0.1]
  initial_params = NArray[*(ks.to_a + [-1])]
  initial_stddev = NArray[*(ks_stddev.to_a + [0.5])]
  throttle = 0.45
  throttle_delta = 0.05

  CSV(STDOUT) do |csv|
    csv << COLUMNS

    loop do
      # Set up the problem. These are the CEM parameters.
      problem = CrossEntropy::ContinuousProblem.new(
        initial_params, initial_stddev.dup
      )
      problem.num_samples = 60
      problem.num_elite = 6
      problem.max_iters = 8

      # Objective function (to be minimized).
      problem.to_score_sample do |params|
        k = NMath.exp(params[0...3]).to_a
        throttle_angle_threshold = 1.0 / (1.0 + Math.exp(-params[3]))
        run_and_log(
          csv, *k, -throttle, throttle, throttle_angle_threshold, max_runtime
        )
      end

      # Do some smoothing when updating the parameters based on new samples.
      # This isn't strictly required, but I find it often helps convergence.
      # Log the results
      smooth = 0.5
      problem.to_update do |new_mean, new_stddev|
        STDERR.puts new_mean.inspect
        STDERR.puts new_stddev.inspect
        smooth_mean = smooth * new_mean + (1 - smooth) * problem.param_mean
        smooth_stddev = smooth * new_stddev +
                        (1 - smooth) * problem.param_stddev
        [smooth_mean, smooth_stddev]
      end

      problem.solve
      STDERR.puts problem.param_mean.inspect

      initial_params = problem.param_mean
      throttle += throttle_delta
      break if throttle > 1
    end
  end
end

staged_cross_entropy(60)
