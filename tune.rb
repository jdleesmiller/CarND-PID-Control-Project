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
  kp ki kd min_throttle max_throttle mean_steer_delay throttle_steer_threshold
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

def cross_entropy_search(throttle, max_runtime)
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
  #ks = NMath.log(NArray[0.07, 0.001, 0.04])
  #ks_stddev = NArray[0.2, 0.2, 0.2]
  #initial_params = NArray[*(ks.to_a + [-2, -2])]
  #initial_stddev = NArray[*(ks_stddev.to_a + [0.5, 0.5])]
  initial_params = NArray[ -2.52046, -6.97938, -3.1024, -1.42986, -2.12784 ]
  initial_stddev = NArray[ 0.06, 0.35, 0.14, 0.48, 0.19 ]
  throttle = 0.7
  throttle_delta = 0.05

  CSV(STDOUT) do |csv|
    csv << COLUMNS

    loop do
      # Set up the problem. These are the CEM parameters.
      problem = CrossEntropy::ContinuousProblem.new(
        initial_params, initial_stddev.dup
      )
      problem.num_samples = 100
      problem.num_elite = 10
      problem.max_iters = 10

      # Objective function (to be minimized).
      problem.to_score_sample do |params|
        # The exp shifts the mean gain depending on the variance, because the
        # mean of a lognormal is exp(mu + var/2); we change the variance between
        # iterations, so it's important to make the gains independent of the
        # CEM variance.
        k_adjustment = problem.param_stddev[0...3]**2 / 2.0
        k = NMath.exp(params[0...3] - k_adjustment).to_a

        # Similarly, the sigmoid shifts the mean depending on the variance. The
        # adjustment, which is approximately valid for small sigma, is based on
        # https://math.stackexchange.com/questions/207861
        # Probably I should use a beta distribution here instead.
        st = NArray[1.0, 1.0] / (1.0 + NMath.exp(-params[3...5]))
        ep = NMath.exp(-problem.param_mean[3...5])
        es = problem.param_stddev[3...5]
        st -= (ep - 1) * ep / 2 / (ep + 1)**3 * es**2
        run_and_log(csv, *k, -throttle, throttle, *st, max_runtime)
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
