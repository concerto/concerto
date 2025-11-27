# Authorization Policy Requirements

This document defines the authorization rules for all models in Concerto. Each section describes the requirements in plain English, which will be used to implement Pundit policies.

**Note:** All policies inherit from `ApplicationPolicy`, which defaults all actions to system admin only. Each policy below overrides these defaults as needed.

---

## How to Use This Document

For each model:

1. **Scope/Index/Show**: Define who can view lists and individual records
2. **Create (new/create)**: Define who can create new records
3. **Update (edit/update)**: Define who can modify existing records
4. **Destroy**: Define who can delete records
5. **Permitted Attributes**: List which fields can be modified, optionally conditional on user role
6. **Special Methods**: Any additional helper methods needed for views or conditional logic

### Permission Shortcuts

- **System Admin**: A user with `is_system_admin: true`
- **Group Member**: A user who is a member (any role) of a group
- **Group Admin**: A user who is an admin of a group
- **Owner**: The user who created the record (via `user_id`)

---

## Completed Policies (Reference Examples)

### Screen Policy ✅

**Scope**: All users (including anonymous) can see all screens

**Index**: Everyone can view the list

**Show**: Everyone can view individual screens

**Create**:
- System admins can create
- Any user who is an admin of ANY group can initiate creation (`new?`)
- To complete creation (`create?`), user must be admin of the assigned group

**Update**:
- System admins can update
- Any member of the screen's group can edit basic fields
- Changing `group_id` requires being admin of BOTH the old group (if it exists) and the new group

**Destroy**:
- System admins can delete
- Admins of the screen's group can delete

**Permitted Attributes**:
- If user can edit group: `[:name, :template_id, :group_id]`
- Otherwise: `[:name, :template_id]`

**Special Methods**:
- `can_edit_group?`: Returns true if user is system admin OR (record is new OR user is admin of the screen's group)

---

### Subscription Policy ✅

**Scope**: All users (including anonymous) can see all subscriptions

**Index**: Everyone can view the list

**Show**: Everyone can view individual subscriptions

**Create**:
- System admins can create
- Any member of the subscription's screen's group can create

**Update**:
- System admins can update
- Any member of the subscription's screen's group can update

**Destroy**:
- System admins can delete
- Any member of the subscription's screen's group can delete

**Permitted Attributes**: (Not explicitly defined, defaults to all params)

---

## Policies to Implement

### User Policy

**Scope**: All signed-in users can see all users

**Index**: Everyone who's signed in can view the list of users

**Show**: Everyone can view an individual user

**Create**: Everyone can create a user. I think this is managed by Devise.

**Update**: A user may only update themselves.

**Destroy**: A user may only destroy themselves.

---

### Group Policy

**Scope**: All users (including anonymous) can see all groups 

**Index**: Everyone can see the list

**Show**: Everyone can view individual groups.

**Create**: Only system administrator can create groups

**Update**: Only admins of the group can update it

**Destroy**: Only system administrators can destroy groups

**Special Considerations**:
- Who can create new groups? => Only system admins
- Can group admins rename their group? => Yes

---

### Membership Policy

**Scope**: All users who can view a group can see memberships in that group.

**Index**: All users who can view a group can see memberships in that group.

**Show**: All users who can view a group can see an individual membership.

**Create**: Only admins of the group may create memberships.

**Update**: Only admins of the group may update memberships.

**Destroy**: A user may remove themselves, or they may be removed by an admins of the group.

**Permitted Attributes**:
- Only admins of the group can set / update the role field.

**Special Considerations**:
- Who can add members to a group? => Admins of the group
- Who can promote members to admin? => Admins of the group
- Can users leave groups? Remove themselves? => Yes. A user may remove themselves OR be removed by an admin of the group.

---

### Template Policy

**Scope**: All users (including anonymous) can see all templates.

**Index**: Everyone can view the list

**Show**: Everyone can view individual templates

**Create**: Any admin of a group owning a screen can create a template.

**Update**: Only system administrators can update templates (for now, until we have a template owner concept)

**Destroy**: Only system administrators can destroy templates (for now, until we have a template owner concept).

**Special Considerations**:
- May need to prevent deletion of templates in use => Yes, templates which are in use should not be deletable.

---

### Position Policy

Positions are managed alongside templates. See template for their instructions.

---

### Field Policy

**Scope**: All users (including anonymous) can see all fields

**Index**: Everyone can view the list

**Show**: Everyone can view individual fields

**Create**: Only system admins

**Update**: Only system admins

**Destroy**: Only system admins

---

### Feed Policy

Feeds work very similiarly to screens.

**Scope**: All users (including anonymous) can see all feeds (for now - we may add options here in the future).

**Index**: Everyone can view the list

**Show**: Everyone can view an individual feed.

**Create**: Any user who is an admin of ANY group can create, the user must be an admin of the group assigned to own the feed.

**Update**: Any member of the feed's group can edit basic fields.  Changing the group_id requires being an admin of both the old group and the new group.

**Destroy**: Admins of the feed's group can delete

**Permitted Attributes**:

**Special Considerations**:
- Similar permission model to screens, with restrictions around group_id.
- SubClasses, like RssFeed, do not have additional restrictions. Still only the group_id limitation.

---

### Content Policy

**Scope**: All users (including anonymous) can see all content

**Index**: Everyone can view the list

**Show**: Everyone can view individual content items

**Create**: All signed-in users can create content

**Update**: Content can only be updated by the owner

**Destroy**: Content can only be destroyed by the owner

---

### Submission Policy

**Scope**: All users who can see a piece of content can see it's submissions.

**Index**: Everyone who can view a piece of content can see the list of submissions.

**Show**: Everyone who can view a piece of content can see individual submissions.

**Create**: Only the owner of a piece of content can create a submission.

**Update**: Submissions cannot be updated yet - we'll add moderation later to support a pending/approved/rejected concept.

**Destroy**: Submissions may be deleted by the owner of the piece of content, or a member of the group owning the associated feed.

---

### Setting Policy

Settings are only for use by system administrators and should not be viewable / create / edit / destroy / etc by other users.


---

## Implementation Checklist

Once requirements are defined above, implement each policy:

- [x] User Policy
- [x] Group Policy
- [x] Membership Policy
- [x] Template Policy
- [x] Position Policy
- [x] Field Policy
- [x] Feed Policy (including RssFeed)
- [x] Content Policy (including RichText, Graphic, Video)
- [x] Submission Policy
- [x] Setting Policy

For each policy:
1. Create `app/policies/{model}_policy.rb`
2. Write policy tests in `test/policies/{model}_policy_test.rb`
3. Update controllers to call `authorize` and `policy_scope`
4. Add `after_action :verify_authorized` to controllers
5. Update views to use `policy(@record).action?` for conditional UI
6. Use `permitted_attributes` in strong parameters

---

## Notes

- All policies inherit default "system admin only" behavior from ApplicationPolicy
- Use `super` in policy methods to include the system admin check
- The pattern `super || custom_logic` allows system admins + specific users
- Remember to define the Scope class for each policy
- Permitted attributes can be conditional (see ScreenPolicy example)
