class FixUserRoles < ActiveRecord::Migration[8.1]
  def up
    # 기존 '일반' 값을 'normal'로 변경
    execute "UPDATE users SET role = 'normal' WHERE role = '일반'"
    
    # 기본값 변경
    change_column_default :users, :role, 'normal'
  end

  def down
    # 롤백 시 기본값을 '일반'으로 되돌림
    change_column_default :users, :role, '일반'
    execute "UPDATE users SET role = '일반' WHERE role = 'normal'"
  end
end
