# Authorization Guidelines

This document outlines the approach for adding authorization to resources in this Rails 8 application. We use the [Pundit](https://github.com/varvet/pundit) gem for authorization. The `Screen` resource has been implemented with this approach, and you can use it as a reference.

## Table of Contents

*   [Glossary](#glossary)
*   [Data Model](#data-model)
*   [General Approach](#general-approach)
*   [Adding Authorization to a New Resource](#adding-authorization-to-a-new-resource)
    *   [1. Create a Policy](#1-create-a-policy)
    *   [2. Update the Controller](#2-update-the-controller)
    *   [3. Update the Views](#3-update-the-views)
    *   [4. Write Tests](#4-write-tests)
*   [Getting Started](#getting-started)

## Glossary

*   **Pundit:** The gem we use for authorization.
*   **Policy:** A Ruby class that encapsulates the authorization logic for a specific model.
*   **Scope:** A class within a policy that is used to scope the records that are visible to the user in the `index` action.
*   **Resource:** A model in the application that we want to add authorization to (e.g., `Screen`, `Content`, `Template`).

## Data Model

Our authorization model is based on the following models and their relationships:

*   **User:** Represents a user of the application.
*   **Group:** Represents a collection of users. A group can have many users, and a user can be in many groups.
*   **Membership:** A join model that connects a user to a group and defines the user's role in that group. A user can be a `member` or an `admin` of a group.
*   **Screen:** The resource we are securing. Each screen belongs to a group.

Here is a simplified diagram of the relationships:

```
+-------+       +-------------+       +-------+
| User  |-------< Membership  >-------| Group |
+-------+       +-------------+       +-------+
                      |
                      |
                      v
+--------+      +----------+
| Screen |------>|  Group   |
+--------+      +----------+
```

## General Approach

Our authorization strategy is based on the user's role and their relationship to the resource through group memberships. Users can be members of groups, and in each group, they can be a regular member or an admin.

The general flow of an authorized request is as follows:

1.  A user attempts to access a controller action.
2.  The `before_action :authenticate_user!` hook in the controller ensures that the user is logged in (except for public actions).
3.  The controller action calls `authorize @record` to check if the user is authorized to perform the action on the given record.
4.  Pundit finds the policy for the record (e.g., `ScreenPolicy` for a `Screen` record).
5.  The policy's action method (e.g., `edit?`) is called with the `user` and `record`.
6.  The policy method returns `true` or `false`, determining whether the user is authorized.
7.  If the user is not authorized, a `Pundit::NotAuthorizedError` is raised, which is rescued by the `ApplicationController` to show an error message.
8.  The `after_action :verify_authorized` and `after_action :verify_policy_scoped` hooks ensure that every action is authorized.

## Adding Authorization to a New Resource

Here are the steps to add authorization to a new resource, using the `Screen` resource as an example.

### 1. Create a Policy

Create a new policy file in `app/policies/`. For a `Content` model, the file would be `app/policies/content_policy.rb`.

```ruby
# app/policies/screen_policy.rb

class ScreenPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    # Screens are visible to all users, even non-logged-in users.
    def resolve
      scope.all
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    # Screens can be created by any admin of any group.
    return false unless user
    user.admin_groups.any?
  end

  def create?
    # Screens can be created by any admin of the associated group.
    return false unless user
    record.group.admin?(user)
  end

  def edit?
    # Screens can be edited by any member of the associated group.
    return false unless user
    record.group.member?(user)
  end

  def update?
    return false unless edit?

    # If group_id is being changed, ensure user is admin of both
    # the current group and the new group.
    if record.group_id_changed?
      # ... (see ScreenPolicy for full implementation)
    end

    true
  end

  def destroy?
    # Screens can be deleted by any admin of the associated group.
    return false unless user
    record.group.admin?(user)
  end

  def permitted_attributes
    if can_edit_group?
      [ :name, :template_id, :group_id ]
    else
      [ :name, :template_id ]
    end
  end

  def can_edit_group?
    return false unless user
    record.new_record? || record.group.admin?(user)
  end
end
```

**Key points:**

*   The `Scope` class is used to scope the records that are visible to the user in the `index` action.
*   Each action in the controller has a corresponding method in the policy (e.g., `show?` for `show`).
*   The `user` is the `current_user` and the `record` is the object being authorized.
*   The `permitted_attributes` method is used to control which attributes can be updated.

### 2. Update the Controller

Update the controller to use the policy.

```ruby
# app/controllers/screens_controller.rb

class ScreensController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  after_action :verify_authorized, except: :index
  after_action :verify_policy_scoped, only: :index

  def index
    @screens = policy_scope(Screen)
  end

  def show
    authorize @screen
    # ...
  end

  def new
    @screen = Screen.new
    authorize @screen
  end

  def create
    @screen = Screen.new(screen_params)
    authorize @screen
    # ...
  end

  def edit
    authorize @screen
  end

  def update
    @screen.assign_attributes(screen_params)
    authorize @screen
    # ...
  end

  def destroy
    authorize @screen
    # ...
  end

  private

  def screen_params
    params.require(:screen).permit(policy(@screen || Screen.new()).permitted_attributes)
  end
end
```

**Key points:**

*   `before_action :authenticate_user!` protects actions that require a logged-in user.
*   `after_action :verify_authorized` and `after_action :verify_policy_scoped` ensure that authorization is performed for every action.
*   `policy_scope(Screen)` in the `index` action uses the `Scope` class from the policy to return the records the user is allowed to see.
*   `authorize @screen` in the other actions calls the corresponding method in the policy to check for authorization.
*   `policy(@screen || Screen.new()).permitted_attributes` is used to sanitize the parameters based on the `permitted_attributes` method in the policy.

### 3. Update the Views

Update the views to conditionally show or hide UI elements based on the user's permissions.

```erb
<%# app/views/screens/index.html.erb %>

<% if policy(Screen.new).new? %>
  <%= link_to "New Screen", new_screen_path %>
<% end %>
```

```erb
<%# app/views/screens/_form.html.erb %>

<% can_edit_group = policy(screen).can_edit_group? %>
<%= form.collection_select :group_id, @groups, :id, :name, {}, disabled: !can_edit_group %>
```

**Key points:**

*   Use `policy(record).action?` to check if the user is authorized to perform an action.
*   This can be used to show or hide links, buttons, and other UI elements.
*   You can also use this to disable form fields, as shown in the `_form.html.erb` example.

### 4. Write Tests

Write tests for the policy and the controller to ensure that the authorization is working correctly.

#### Policy Tests

Create a new policy test file in `test/policies/`. For a `Content` model, the file would be `test/policies/content_policy_test.rb`.

```ruby
# test/policies/screen_policy_test.rb

require "test_helper"

class ScreenPolicyTest < ActiveSupport::TestCase
  setup do
    @group_admin_user = users(:admin)
    @group_regular_user = users(:regular)
    @non_group_user = users(:non_member)
    @screen = screens(:one)
  end

  test "edit? is permitted for a regular group member" do
    assert ScreenPolicy.new(@group_regular_user, @screen).edit?
  end

  test "edit? is denied for a non-group member" do
    refute ScreenPolicy.new(@non_group_user, @screen).edit?
  end

  # ... (see ScreenPolicyTest for more examples)
end
```

#### Controller Tests

Update the controller tests to check for authorization.

```ruby
# test/controllers/screens_controller_test.rb

require "test_helper"

class ScreensControllerTest < ActionDispatch::IntegrationTest
  setup do
    @screen = screens(:one)
  end

  test "should not get edit if not authorized" do
    sign_in users(:non_member)
    get edit_screen_url(@screen)
    assert_redirected_to root_url # Or wherever you redirect unauthorized users
  end

  # ... (see ScreensControllerTest for more examples)
end
```

By following these steps, you can add robust authorization to any resource in the application.

## Getting Started

To get started with developing and testing the authorization system, you will need to:

1.  **Set up the development environment:** Follow the instructions in the `README.md` file to set up the development environment.
2.  **Run the tests:** Run `bin/rails test` to run the test suite.
3.  **Relevant files:**
    *   Policies: `app/policies/`
    *   Controllers: `app/controllers/`
    *   Views: `app/views/`
    *   Tests: `test/policies/` and `test/controllers/`
    *   Models: `app/models/`
    *   Schema: `db/schema.rb`