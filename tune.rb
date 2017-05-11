# frozen_string_literal: true

require 'csv'
require 'English'
require 'json'
require 'tmpdir'

require 'cross_entropy'

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

def run_and_log(csv, *params, max_runtime )
  status, out, _err = run(*params, max_runtime)
  if [0, 1].member?(status)
    crashed = status == 1
    stats = JSON.parse(out)
    csv << [
      *params,
      crashed,
      stats['runtime'], stats['distance'], stats['total_absolute_cte']
    ]
    stats
  else
    # The run failed.
    csv << params
    nil
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
      stats = run_and_log(csv, *k, *throttle, max_runtime)
      if stats
        -stats['distance'] +
          TOTAL_ABSOLUTE_CTE_WEIGHT * stats['total_absolute_cte']
      else
        Float::INFINITY # simulator crashed; bad luck
      end
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
    STDERR.puts problems.param_mean.inspect
  end
end

cross_entropy_search(90)
exit

def twiddle(params, deltas, max_runtime, tolerance)
  param_indexes = 0...(params.size)
  CSV(STDOUT) do |csv|
    csv << COLUMNS
    best_score = -run_and_log(csv, *params, max_runtime)['distance']
    while deltas.sum > tolerance
      param_indexes.each do |i|
        params[i] += deltas[i]
        score = -run_and_log(csv, *params, max_runtime)['distance']
        if score < best_score
          best_score = score
          deltas[i] *= 1.1
        else
          params[i] -= 2 * deltas[i]
          score = -run_and_log(csv, *params, max_runtime)['distance']
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
