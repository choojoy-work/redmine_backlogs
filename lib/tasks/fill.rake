namespace :redmine do
  namespace :backlogs do
    task :fill => :environment do
      project = Project.find_by_identifier("test")
      project.destroy unless project.nil?

      project = Project.create(name: "Сайт для всей семьи", identifier: "test")

      users = []
      [
          { firstname: "Павел", lastname: "Богданов" },
          { firstname: "Андрющенко", lastname: "Никита" },
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
          "Сделать релиз сервиса \"Поиск\"",
          "По информации от системного администратора в API долго формируются списки фото в коллекциях, необходимо проанализировать",
          "Проектирование архитектуры сервиса \"Идеи\"",
          "Убрать ссылки на следующий и предыдущий пост со страницы поста",
          "Реализовать недостающие методы API для страницы подписок",
          "Реализовать страницу подписок на клубы",
          "Реализовать функционал обновления ленты пользователя при изменении набора подписок",
          "Условный вывод хлебных крошек и фиолетового пользовательского виджета в зависимости от версии устройства",
          "Проанализировать ситуацию с падением поискового трафика",
          "Добавить вопросы консультации в карту сайта",
          "Оптимизация изображений в мобильной версии сайта",
          "Сделать релиз сервиса \"Прямой эфир\"",
          "Перевод ленты прямого эфира на новый дизайн",
          "Реализовать поддержку тега picture расширенным редактором постов",
          "Адаптивная верстка постов на главной странице",
          "Убрать со страниц блокирующий клиентский код (сделать асинхронным)",
          "Отправка рекламной рассылки о консультации",
          "Отладка подсистемы подсчета просмотров",
          "Реализовать парсер статистики просмотров из Google Analytics",
          "Изучение функциональности сервиса Double click",
          "Решить проблему с таймаутом mysql в консольных командах",
          "Написание миграции данных для обновления сервиса \"Семья\"",
          "Проектирование структуры БД для сервиса \"Семья\"",
          "Подготовить инструкцию по настройке окружения сервиса \"Мои фотоальбомы\" для системного администратора",
          "Интеграция фотоальбомов с сервисом обработки фото aviary",
          "Реализовать функционал установки, удаления и получения аватары",
          "Подготовка миграции для перехода к новому варианту хранения аватар",
          "Реализовать управление кадрированными фото на уровне хранения данных",
          "Реализовать возможность изменения фото с помощью редактора",
          "Общее проектирование модуля \"мои фотоальбомы\". Составление списка компонентов модуля, распределение ответственности, обозначение связей и выбор технологий",
          "Исправление неправильной ссылки на автора материала в RSS",
          "Настроить рекламную кампанию (брендирование)",
          "Установка Redmine",
          "Установка плагина оценки успешности проекта",
          "Внедрение новой адаптивной верстки в сервис \"Маршруты\"",
          "Анализ дублирующихся названий страниц по данным сервиса Google Analytics",
          "Передать на тестирование задачи по низкокачественному контенту",
          "Убирать точку в конце заголовка в постах/рецептах",
          "Не работает привязка профиля из google plus - проанализировать",
          "Добавть заголовок Vary для адаптивных контроллеров",
          "Исправить ClientScript в соответствии с накопившемся опытом работы с requirejs и внедрением lite-версии",
          "Внедрение технологии requirejs на страницы постов",
          "Рефакторинг виджета быстрых сообщений",
      ]

      10.times do |i|
        name = "Спринт " + i.to_s
        startDate = (Time.now + (2*7*24*60*60*i)).strftime("%Y-%m-%d")
        puts startDate
        endDate = (Time.now + (4*7*24*60*60*i)).strftime("%Y-%m-%d")
        sprint = RbSprint.create(project_id: project.id, sprint_start_date: startDate, effective_date: endDate, name: name)

        closed_rate = 55 + rand(46)
        t = 3 + rand(4)

        t.times do |j|
          subject = names[(i * 10 + j) % names.length]
          acceptance_rate = -2 + rand(5)
          story_points = 1 + rand(8)
          status_id = rand(101) < closed_rate ? 5 : 2

          issue = Issue.create(tracker_id: 2, assigned_to_id: project.members.sample.user.id, author_id: 1, project_id: project.id, fixed_version_id: sprint.id, subject: subject, acceptance_rate: acceptance_rate, story_points: story_points, status_id: status_id)
          puts issue.errors.full_messages
        end
      end

      5.times do |j|
        subject = names[j % names.length]
        issue = Issue.create(tracker_id: 2, assigned_to_id: project.members.sample.user.id, author_id: 1, project_id: project.id, subject: subject, status_id: 1, lock_version: 1)
        puts issue.errors.full_messages
      end
    end
  end
end
