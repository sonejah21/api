require 'rails_helper'

feature 'Group creation' do
  scenario 'admin creates a group', :js do
    login_as(create(:staff, :admin))
    member_staff = create(:staff)
    group = build(:group)
    visit '/admin/groups/list'
    click_on('Add New Group')

    fill_in('Group Name', with: group.name)
    fill_in('Group Description', with: group.description)
    selectize('#group_users', option: member_staff.email)
    click_on 'CREATE NEW GROUP'

    expect(all('.group-box-cell')).to have_content(group.name)
  end
end
