# frozen_string_literal: true

module BK
  module Compat
    # CircleCI translation scaffolding
    class GitHubActions

      def parse_jobs(bk_pipeline)
        @jobs.each do |job|

        # Extract the Job's name
          job_name = job[0]
          job_needs = @jobs[job_name]['needs']
          
          # Put info to console
          puts("Job name: #{job_name}")
          puts("Steps: #{@jobs[job_name]['steps']}")
          puts("Job needs: #{job_needs}")
  
          # For each job, extract the name/run
          parse_job_steps(job, steps = [])
  
          # Create a Group Step
          groups = BK::Compat::GroupStep.new(
            label: ":github:: #{job[0]}",
            key: job_name,
            steps: steps,
            depends_on: job_needs
          )
  
          ## Insert Group into pipeline
          bk_pipeline.steps << groups
        end
      end

      def parse_job_steps(job, steps)
        job[1]['steps'].each do |step|
              
          bk_step = BK::Compat::CommandStep.new(
              label: step['name'],
              commands: step['run']
          )
  
          steps.append(bk_step)
        end 
      end
    end
  end
end
  