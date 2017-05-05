require 'csv'
require 'English'
require 'json'
require 'tmpdir'

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

def grid(max_runtime)
  CSV(STDOUT) do |csv|
    csv << %w(kp ki kd crashed runtime distance total_absolute_cte)
    ks = (0..4).map { |k| k / 20.0 }
    ks.product(ks, ks).each do |kp, ki, kd|
      status, out, _err = run(kp, ki, kd, max_runtime)
      if [0, 1].member?(status)
        crashed = status == 1
        stats = JSON.parse(out)
        csv << [
          kp, ki, kd,
          crashed,
          stats['runtime'], stats['distance'], stats['total_absolute_cte']
        ]
      else
        # The run failed.
        csv << [kp, ki, kd]
      end
    end
  end
end

grid(60)

