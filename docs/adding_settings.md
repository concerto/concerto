# Adding a New Setting

This guide walks through adding a new application setting to Concerto. Settings are stored in the database and managed by admins at `/admin/settings`.

## Overview

The settings system has three parts:

1. **`Setting` model** (`app/models/setting.rb`) — stores settings in a key-value table with type casting, caching, and encryption support.
2. **`Setting::DEFAULTS` hash** — declares every setting the app expects, with its default value. This drives automatic creation of missing settings on existing installations.
3. **Admin settings view** (`app/views/admin/settings.html.erb`) — a hardcoded form that renders each setting with its label, input, and description.

## Steps

### 1. Add the default value

In `app/models/setting.rb`, add your setting to the `DEFAULTS` hash:

```ruby
DEFAULTS = {
  "public_registration" => true,
  "update_prerelease" => false,
  "my_new_setting" => "default_value",   # <-- add here
  "oidc_issuer" => "",
  "oidc_client_id" => "",
  "oidc_client_secret" => nil
}.freeze
```

The type is inferred from the default value:

| Default value | Stored type | Example |
|---|---|---|
| `true` / `false` | boolean | `"my_flag" => false` |
| `""` or `"text"` | string | `"my_url" => ""` |
| `42` | integer | `"my_count" => 10` |
| `nil` (key ends in `_secret`) | secret (encrypted) | `"api_secret" => nil` |

### 2. Add the UI

Edit `app/views/admin/settings.html.erb` and add the form fields for your setting in the appropriate section (or create a new section).

**Boolean settings** use a checkbox:

```erb
<div>
  <%= label_tag "settings[my_flag]", "My Flag", class: "frm-label" %>
  <div class="flex items-center gap-3">
    <%= hidden_field_tag "settings[my_flag]", "false" %>
    <%= check_box_tag "settings[my_flag]", "true", @settings["my_flag"]&.typed_value,
        class: "h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600" %>
    <p class="text-sm text-gray-500">Description of what this does.</p>
  </div>
</div>
```

**String/integer settings** use a text input:

```erb
<div>
  <%= label_tag "settings[my_url]", "My URL", class: "frm-label" %>
  <%= text_field_tag "settings[my_url]", @settings["my_url"]&.typed_value, class: "frm-input" %>
  <p class="mt-1 text-sm text-gray-500">Description of what this does.</p>
</div>
```

**Secret settings** use a password input:

```erb
<div>
  <%= label_tag "settings[my_secret]", "My Secret", class: "frm-label" %>
  <%= password_field_tag "settings[my_secret]", "",
      placeholder: "Leave blank to keep unchanged", class: "frm-input" %>
  <p class="mt-1 text-sm text-gray-500">Description of what this does.</p>
</div>
```

### 3. Read the setting in code

Use the bracket accessor anywhere in the app:

```ruby
Setting[:my_new_setting]          # read (cached, type-cast)
Setting[:my_new_setting] = value  # write (invalidates cache)
```

Values are automatically cached (except secrets, which bypass the cache to avoid storing plaintext).

### 4. Add a test fixture

In `test/fixtures/settings.yml`, add a fixture so the setting exists in tests:

```yaml
my_new_setting:
  key: my_new_setting
  value: "default_value"
  value_type: string
```

### 5. Write tests

- Test the behavior that depends on your setting in the relevant test file.
- The admin controller tests in `test/controllers/admin_controller_test.rb` verify the settings page renders all expected inputs and handles updates.

## How it works on existing installations

No migration is needed. When an admin visits the settings page, the controller calls `Setting.ensure_defaults_exist`, which creates any settings from `DEFAULTS` that don't yet exist in the database. Existing settings are never overwritten.

The same method is called during `db:seed` for fresh installations.

## Database schema

Settings are stored in a single table:

| Column | Purpose |
|---|---|
| `key` | Unique identifier (e.g., `"public_registration"`) |
| `value` | Stored value as a string |
| `value_type` | Type hint: `string`, `boolean`, `integer`, `array`, `hash`, or `secret` |
| `encrypted_value` | Encrypted storage for secret-type settings |
