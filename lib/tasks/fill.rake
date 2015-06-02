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
          # { firstname: "Руслан", lastname: "Баранов" },
          # { firstname: "Юрий", lastname: "Суханов" },
          { firstname: "Давид", lastname: "Терентьев" }
      ].each_with_index do |data, index|
        data[:login] = "developer" + project.id.to_i.to_s + index.to_s
        data[:mail] = data[:login] + "@gmail.com"
        user = User.create(data, :without_protection => true)
        r = Role.find(4)
        m = Member.new(:user => user, :roles => [r])
        project.members << m
      end

      names = [
          "Анализ теоретических основ гибкого управления",
          "Изучение практики внедрения гибкого управления",
          "Сравнтиельный анализ с традиционными методами проектного управления",
          "Изучение методологии Scrum",
          "Изучение семейства методологий Crystal",
          "Изучение методологии экстремального программирования",
          "Изучение методологии адаптивной разработки",
          "Проведение экспертного опроса",
          "Анализ результатов экспертного опроса",
          "Отчет по научно-исследовательской работе",
          "Выбор наиболее подходящей методологии",
          "Выделение критериев успешности",
          "Описание требований к системе оценки",
          "Изучение метода MAUT",
          "Изучение метода AHP",
          "Изучение метода Electre",
          "Изучение метода нечеткого вывода",
          "Выбор наиболее подходящего метода оценки",
          "Рассмотрение этапа фаззификации",
          "Рассмотрение этапа агрегирования",
          "Рассмотрение этапа активизации",
          "Рассмотрение этапа аккумуляции",
          "Рассмотрение этапа дефаззификации",
          "Подготовка базы правил нечетких продукций",
          "Конвертация баз данных анализируемых проектов",
          "Сравнение результатов, получненных различными методами нечеткого вывода",
          "Выбор наиболее подходящего метода нечеткого вывода",
          "Отчет по научно-исследовательской практике",
          "Описание требований к разрабатываемой системе",
          "Выбор платформы для реализации",
          "Реализация системы нечеткого вывода",
          "Преддипломная практика",
          "Установка Redmine",
          "Создание пустого плагина",
          "Добавление свойства степени удовлетворенности",
          "Добавление критериев приемки",
          "Добавление функциональности бэклога",
          "Подключение библиотеки для отображения графиков",
          "Реализация радарного графика в рамках спринта",
          "Реализация линейного графика в рамках проекта",
          "Подготовка презентации",
          "Подготовка доклада к презентации",
          "Прохождение нормоконтроля",
      ]

      10.times do |i|
        name = "Спринт " + i.to_s
        startDate = (Time.now + (2*7*24*60*60*i)).strftime("%Y-%m-%d")
        puts startDate
        endDate = (Time.now + (4*7*24*60*60*i)).strftime("%Y-%m-%d")
        sprint = RbSprint.create(project_id: project.id, sprint_start_date: startDate, effective_date: endDate, name: name)

        closed_rate = 55 + rand(46)
        5.times do |j|
          subject = names[(i * 10 + j) % names.length]
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
