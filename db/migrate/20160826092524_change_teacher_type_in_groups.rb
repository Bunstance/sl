class ChangeTeacherTypeInGroups < ActiveRecord::Migration
	change_column :groups, :teacher, :string
end
