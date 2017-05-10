# frozen_string_literal: true

require 'csv'
require 'English'
require 'json'
require 'tmpdir'

require 'cross_entropy'

TOTAL_ABSOLUTE_CTE_WEIGHT = 2

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

def run_and_log(csv, kp, ki, kd, max_throttle, max_runtime)
  status, out, _err = run(kp, ki, kd, max_throttle, max_runtime)
  if [0, 1].member?(status)
    crashed = status == 1
    stats = JSON.parse(out)
    csv << [
      kp, ki, kd, max_throttle,
      crashed,
      stats['runtime'], stats['distance'], stats['total_absolute_cte']
    ]
    stats
  else
    # The run failed.
    csv << [kp, ki, kd, max_throttle]
    nil
  end
end

def grid(max_runtime)
  CSV(STDOUT) do |csv|
    csv << %w(kp ki kd crashed runtime distance total_absolute_cte)
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
  ks = NArray[-1.0, -1.0, -1.0, 0.0]
  ks_stddev = NArray[2.0, 2.0, 2.0, 2.0]

  # Set up the problem. These are the CEM parameters.
  problem = CrossEntropy::ContinuousProblem.new(ks, ks_stddev)
  problem.num_samples = 120
  problem.num_elite = 12
  problem.max_iters = 20

  CSV(STDOUT) do |csv|
    csv << %w(kp ki kd max_throttle crashed runtime distance total_absolute_cte)

    # Objective function (to be minimized).
    problem.to_score_sample do |params|
      k = params.to_a.take(3).map { |x| Math.exp(x) }
      max_throttle = 1.0 / (1.0 + Math.exp(-params[3]))
      stats = run_and_log(csv, *k, max_throttle, max_runtime)
      if stats
        -stats['distance'] +
          TOTAL_ABSOLUTE_CTE_WEIGHT * stats['total_absolute_cte']
      else
        Float::INFINITY # simulator crashed; bad luck
      end
    end

    # Log the results
    problem.to_update do |new_mean, new_stddev|
      STDERR.puts new_mean.inspect
      STDERR.puts new_stddev.inspect
      [new_mean, new_stddev]
    end

    problem.solve
    STDERR.puts problems.param_mean.inspect
  end
end

# cross_entropy_search(60)

def twiddle(params, deltas, max_runtime, tolerance)
  param_indexes = 0...(params.size)
  CSV(STDOUT) do |csv|
    csv << %w(kp ki kd max_throttle crashed runtime distance total_absolute_cte)
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

twiddle([0.1, 0.0025, 0.01, 0.3], [0.1, 0.1, 0.1, 0.1], 90, 0.01)
