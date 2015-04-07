namespace :redmine do
  namespace :backlogs do
    task :fill => :environment do
      project = Project.find_by_identifier("test")
      project.destroy unless project.nil?

      project = Project.create(name: "Тестовый проект", identifier: "test")

      users = []
      [
          { firstname: "Павел", lastname: "Богданов" },
          { firstname: "Ефим", lastname: "Пономарёв" },
          { firstname: "Руслан", lastname: "Баранов" },
          { firstname: "Юрий", lastname: "Суханов" },
          { firstname: "Давид", lastname: "Терентьев" }
      ].each_with_index do |data, index|
        data[:login] = "developer" + project.id.to_i.to_s + index.to_s
        data[:mail] = data[:login] + "@gmail.com"
        user = User.create(data, :without_protection => true)
        r = Role.find(4)
        m = Member.new(:user => user, :roles => [r])
        project.members << m
      end

      10.times do |i|
        name = "Спринт " + i.to_s
        startDate = (Time.now + (2*7*24*60*60*i)).strftime("%Y-%m-%d")
        puts startDate
        endDate = (Time.now + (4*7*24*60*60*i)).strftime("%Y-%m-%d")
        sprint = RbSprint.create(project_id: project.id, sprint_start_date: startDate, effective_date: endDate, name: name)

        closed_rate = 55 + rand(46)
        30.times do |j|
          subject = "Задача " + (10 * i + j).to_s
          acceptance_rate = -2 + rand(5)
          story_points = 1 + rand(8)
          status_id = rand(101) < closed_rate ? 5 : 1

          issue = Issue.create(tracker_id: 2, assigned_to_id: project.members.sample.user.id, author_id: 1, project_id: project.id, fixed_version_id: sprint.id, subject: subject, acceptance_rate: acceptance_rate, story_points: story_points, status_id: status_id)
          puts issue.errors.full_messages
        end
      end
    end
  end
end
