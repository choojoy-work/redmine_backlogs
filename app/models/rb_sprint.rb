require 'date'
require 'fuzzy'
include Fuzzyrb

class RbSprint < Version
  unloadable

  validate :start_and_end_dates

  def start_and_end_dates
    errors.add(:base, "sprint_end_before_start") if self.effective_date && self.sprint_start_date && self.sprint_start_date >= self.effective_date
  end

  def self.rb_scope(symbol, func)
    if Rails::VERSION::MAJOR < 3
      named_scope symbol, func
    else
      scope symbol, func
    end
  end

  rb_scope :open_sprints, lambda { |project|
    order = Backlogs.setting[:sprint_sort_order] == 'desc' ? 'DESC' : 'ASC'
    {
      :order => "CASE sprint_start_date WHEN NULL THEN 1 ELSE 0 END #{order},
                 sprint_start_date #{order},
                 CASE effective_date WHEN NULL THEN 1 ELSE 0 END #{order},
                 effective_date #{order}",
      :conditions => [ "status = 'open' and project_id = ?", project.id ] #FIXME locked, too?
    }
  }

  #TIB ajout du scope :closed_sprints
  rb_scope :closed_sprints, lambda { |project|
    order = Backlogs.setting[:sprint_sort_order] == 'desc' ? 'DESC' : 'ASC'
    {
      :order => "CASE sprint_start_date WHEN NULL THEN 1 ELSE 0 END #{order},
                 sprint_start_date #{order},
                 CASE effective_date WHEN NULL THEN 1 ELSE 0 END #{order},
                 effective_date #{order}",
      :conditions => [ "status = 'closed' and project_id = ?", project.id ]
    }
  }

  #depending on sharing mode
  #return array of projects where this sprint is visible
  def shared_to_projects(scope_project)
    @shared_projects ||=
      begin
        # Project used when fetching tree sharing
        r = self.project.root? ? self.project : self.project.root
        # Project used for other sharings
        p = self.project
        Project.visible.scoped(:include => :versions,
          :conditions => ["#{Version.table_name}.id = #{id}" +
          " OR (#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED} AND (" +
          " 'system' = ? " +
          " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND ? = 'tree')" +
          " OR (#{Project.table_name}.lft > #{p.lft} AND #{Project.table_name}.rgt < #{p.rgt} AND ? IN ('hierarchy', 'descendants'))" +
          " OR (#{Project.table_name}.lft < #{p.lft} AND #{Project.table_name}.rgt > #{p.rgt} AND ? = 'hierarchy')" +
          "))",sharing,sharing,sharing,sharing]).order('lft')
      end
    @shared_projects
  end

  def stories
    return RbStory.sprint_backlog(self)
  end

  def points
    return stories.inject(0){|sum, story| sum + story.story_points.to_i}
  end

  def has_wiki_page
    return false if wiki_page_title.blank?

    page = project.wiki.find_page(self.wiki_page_title)
    return false if !page

    template = find_wiki_template
    return false if template && page.text == template.text

    return true
  end

  def find_wiki_template
    projects = [self.project] + self.project.ancestors

    template = Backlogs.setting[:wiki_template]
    if template =~ /:/
      p, template = *template.split(':', 2)
      projects << Project.find(p)
    end

    projects.compact!

    projects.each{|p|
      next unless p.wiki
      t = p.wiki.find_page(template)
      return t if t
    }
    return nil
  end

  def wiki_page
    if ! project.wiki
      return ''
    end

    self.update_attribute(:wiki_page_title, Wiki.titleize(self.name)) if wiki_page_title.blank?

    page = project.wiki.find_page(self.wiki_page_title)
    if !page
      template = find_wiki_template
      if template
      page = WikiPage.new(:wiki => project.wiki, :title => self.wiki_page_title)
      page.content = WikiContent.new
      page.content.text = "h1. #{self.name}\n\n#{template.text}"
      page.save!
      end
    end

    return wiki_page_title
  end

  def eta
    return nil if ! self.sprint_start_date

    dpp = self.project.scrum_statistics.info[:average_days_per_point]
    return nil if !dpp

    derived_days = if Backlogs.setting[:include_sat_and_sun]
                     Integer(self.points * dpp)
                   else
                     # 5 out of 7 are working days
                     Integer(self.points * dpp * 7.0/5)
                   end
    return self.sprint_start_date + derived_days
  end

  def activity
    bd = self.burndown

    # assume a sprint is active if it's only 2 days old
    return true if bd[:hours_remaining] && bd[:hours_remaining].compact.size <= 2

    return Issue.exists?(['fixed_version_id = ? and ((updated_on between ? and ?) or (created_on between ? and ?))', self.id, -2.days.from_now, Time.now, -2.days.from_now, Time.now])
  end

  def impediments
    @impediments ||= Issue.find(:all,
      :conditions => ["id in (
              select issue_from_id
              from issue_relations ir
              join issues blocked
                on blocked.id = ir.issue_to_id
                and blocked.tracker_id in (?)
                and blocked.fixed_version_id = (?)
              where ir.relation_type = 'blocks'
              )",
            RbStory.trackers + [RbTask.tracker],
            self.id]
      ) #.sort {|a,b| a.closed? == b.closed? ?  a.updated_on <=> b.updated_on : (a.closed? ? 1 : -1) }
  end

  def acceptance_rate
    self.acceptance_rate_internal(self.fixed_issues)
  end

  def prev
    return RbSprint.where("id < ?", self.id).where("project_id = ?", self.project_id).order("id DESC").first
  end

  def dynamics
    return self.acceptance_rate - self.prev.acceptance_rate
  end

  def planning
    good = FuzzySet.trapezoid([80, 90, 100, 100])
    normal = FuzzySet.trapezoid([70, 80, 80, 90])
    bad = FuzzySet.trapezoid([0, 0, 50, 75])

    rules = []
    rules << FuzzyRule.new([good], FuzzySet.trapezoid([0.99, 1, 1, 1]))
    rules << FuzzyRule.new([normal], FuzzySet.trapezoid([1.1, 1.2, 1.2, 1.5]))
    rules << FuzzyRule.new([bad], FuzzySet.trapezoid([1.2, 1.5, 1.5, 2]))

    ms = MamdaniImplication.new(rules)
    ms.evaluate([50], {:t_norm => :min, :implication => :mamdani, :defuzzification => :firstMaximum})
  end

  def acceptance_inference(acceptance_rate, dynamics)
    bad = FuzzySet.trapezoid([-2, -2, -2, 0])
    normal = FuzzySet.trapezoid([-0.5, 0, 0, 0.5])
    good = FuzzySet.trapezoid([0, 2, 2, 2])

    dBad = FuzzySet.trapezoid([-4, -4, -4, 0])
    dNormal = FuzzySet.trapezoid([-1, 0, 0, 1])
    dGood = FuzzySet.trapezoid([0, 4, 4, 4])

    rules = []
    rules << FuzzyRule.new([good, dNormal], good)
    rules << FuzzyRule.new([good, dBad], bad)
    rules << FuzzyRule.new([good, dGood], good)
    rules << FuzzyRule.new([normal, dNormal], normal)
    rules << FuzzyRule.new([normal, dBad], bad)
    rules << FuzzyRule.new([normal, dGood], good)
    rules << FuzzyRule.new([bad, dNormal], bad)
    rules << FuzzyRule.new([bad, dBad], bad)
    rules << FuzzyRule.new([bad, dGood], normal)
    ms = MamdaniImplication.new(rules)
    res = ms.evaluate([acceptance_rate, dynamics], {:t_norm => :min, :implication => :larsen, :defuzzification => :firstMaximum})
    case res
      when 2
        "Хорошо"
      when 0
        "Нормально"
      when - 2
        "Плохо"
    end
  end

  def teamwork
    self.acceptance_inference(acceptance_rate, dynamics)
  end

  def personal_work(member)
    issues = []
    self.fixed_issues.each do |issue|
      if issue.assigned_to_id == member.user.id
        issues << issue
      end
    end


    personal_acceptance_rate = acceptance_rate_internal(issues)



    issues.clear
    self.prev.fixed_issues.each do |issue|
      if issue.assigned_to_id == member.id
        issues << issue
      end
    end

    if issues.length == 0
      dynamics = 0
    else
      dynamics = acceptance_rate_internal(issues) - personal_acceptance_rate
    end

    return self.acceptance_inference(personal_acceptance_rate, dynamics)
  end

  def acceptance_rate_internal(issues)
    return 0 if issues.count == 0

    sum = 0
    issues.each do |issue|
      sum += issue.acceptance_rate if issue.acceptance_rate.is_a? Integer
    end
    return sum.to_f / issues.count
  end
end
