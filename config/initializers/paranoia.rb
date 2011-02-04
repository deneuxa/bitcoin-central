# This initializer forces models to whitelist mass-assignable attributes
# instead of relying on blacklisting the ones that shouldn't be used in
# mass-assignments
ActiveRecord::Base.send(:attr_accessible, nil)