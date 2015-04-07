class PerformanceController < RbApplicationController
  unloadable

  def index
    @member = params[:member_id].nil? ? nil : Member.find(params[:member_id])
  end
end
