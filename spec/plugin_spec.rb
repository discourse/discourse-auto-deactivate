# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jobs::AutoDeactivateUsers do
  it "returns only users where last_seen_at is greater than 1 year" do
    created_over_a_year_ago = Fabricate(:user, created_at: 366.days.ago)
    created_today = Fabricate(:user)

    result = Jobs::AutoDeactivateUsers.to_deactivate

    expect(result.count).to eq 1
    expect(result.first).to eq created_over_a_year_ago
  end

  it "returns only users not in safe groups" do
    created_over_a_year_ago = Fabricate(:user, created_at: 366.days.ago)
    user_is_in_safe_group = Fabricate(:admin, created_at: 366.days.ago)
    staff_group = Group.where(name: "staff").first
    staff_group.add(user_is_in_safe_group)

    deactivate_list = Jobs::AutoDeactivateUsers.to_deactivate
    safe_to_deactivate = Jobs::AutoDeactivateUsers.exclude_users_in_safe_groups(deactivate_list)

    expect(safe_to_deactivate.count).to eq 1
    expect(safe_to_deactivate.first).to eq created_over_a_year_ago
  end

  it "does not include real users" do
    created_over_a_year_ago = Fabricate(:user, created_at: 366.days.ago)
    Discourse.system_user.created_at = 366.days.ago
    Discourse.system_user.save

    result = Jobs::AutoDeactivateUsers.to_deactivate

    expect(result.count).to eq 1
    expect(result.first).to eq created_over_a_year_ago
  end

  it "checks correct user is deactivated and right message is put in user history details" do
    SiteSetting.auto_deactivate_enabled = true

    created_over_a_year_ago = Fabricate(:user, created_at: 366.days.ago)
    created_today = Fabricate(:user)

    auto_deactivate_users = Jobs::AutoDeactivateUsers.new
    auto_deactivate_users.execute({})

    expect(created_over_a_year_ago.reload.active).to eq(false)
    expect(created_today.reload.active).to eq(true)
    expect(UserHistory.last.details).to eq I18n.t(
         "discourse_auto_deactivate.deactivate_reason",
         count: SiteSetting.auto_deactivate_after_days,
       )
  end
end
