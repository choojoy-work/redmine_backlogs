class Story < Issue
    unloadable

    acts_as_list :scope => 'coalesce(cast(issues.fixed_version_id as char), \'\') = \'#{fixed_version_id}\' AND issues.parent_id is NULL'

    named_scope :product_backlog, lambda { |project|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and project_id = ? and tracker_id = ? and fixed_version_id is NULL",
                project.id, Setting.plugin_redmine_backlogs[:story_tracker]
                ]
        }
    }

    named_scope :sprint_backlog, lambda { |sprint|
        {
            :order => 'position ASC',
            :conditions => [
                "parent_id is NULL and tracker_id = ? and fixed_version_id = ?",
                Setting.plugin_redmine_backlogs[:story_tracker], sprint.id
                ]
        }
    }

    def self.is_story(id)
        return ! Story.find(:id => id, parent_id => nil, tracker_id => Setting.plugin_redmine_backlogs[:story_tracker]).nil?
    end

    def set_points(p)
        self.init_journal(User.current)

        if p.nil? || p == '' || p == '-'
            self.update_attribute(:story_points, nil)
            return
        end

        if p.downcase == 's'
            self.update_attribute(:story_points, 0)
            return
        end

        p = Integer(p)
        if p >= 0
            self.update_attribute(:story_points, p)
            return
        end
    end

    def points_display(notsized='-')
        if story_points.nil?
            return notsized
        end

        if story_points == 0
            return 'S'
        end

        return story_points.to_s
    end

    def abbreviated_subject
        cap = 60
        subject = read_attribute(:subject)
        if subject.length > cap
            return subject[0,cap - 3] + '...'
        else
            return subject
        end
    end
end