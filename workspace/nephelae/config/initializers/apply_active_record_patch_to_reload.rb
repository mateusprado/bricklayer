# ActiveRecord's reload is affected by default_scope. This is a bug reported on Lighthouse on the following link:
# https://rails.lighthouseapp.com/projects/8994/tickets/3166-patch-activerecordbasereload-didnt-respect-default_scope-conditions
# TODO: Remove this monkey patch when this specific fix is commited to the mainline
class ActiveRecord::Base
  def reload(options = nil)
    clear_aggregation_cache
    clear_association_cache
    @attributes.update(self.class.send(:with_exclusive_scope) { self.class.find(self.id, options) }.instance_variable_get('@attributes'))
    @attributes_cache = {}
    self
  end
end
