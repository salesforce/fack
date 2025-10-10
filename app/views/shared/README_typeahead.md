# Typeahead Component

A reusable typeahead/autocomplete input component for Rails forms that fetches data from a search endpoint.

## Files

- **Partial**: `app/views/shared/_typeahead.html.erb`
- **Stimulus Controller**: `app/javascript/controllers/typeahead_controller.js`

## Usage

```erb
<%= render 'shared/typeahead', 
    form: form, 
    field_name: :user_id, 
    search_url: search_users_path,
    label_text: 'Owner',
    placeholder: 'Start typing to search for a user...',
    help_text: 'Type at least 2 characters to search for users by email',
    current_value: @record.user&.email %>
```

## Parameters

### Required Parameters

- **`form`**: The form builder object
- **`field_name`**: The name of the field (symbol, e.g., `:user_id`)
- **`search_url`**: The URL endpoint for searching (e.g., `search_users_path`)
- **`label_text`**: The label text to display

### Optional Parameters

- **`placeholder`**: Placeholder text for the input (default: "Start typing to search...")
- **`help_text`**: Help text to display below the input
- **`min_length`**: Minimum characters before search starts (default: 2)
- **`current_value`**: Current display value for the input (for editing existing records)
- **`input_class`**: Additional CSS classes for the input field
- **`container_class`**: Additional CSS classes for the container div

## Backend Requirements

Your search endpoint should:

1. Accept a `q` parameter for the search query
2. Return JSON in the format: `[{id: 1, email: "user@example.com"}, ...]`
3. Handle case-insensitive partial matching
4. Limit results (recommended: 10-20 items)

### Example Controller Action

```ruby
def search
  query = params[:q]
  if query.present?
    @users = User.where("email ILIKE ?", "%#{query}%")
                 .order(:email)
                 .limit(10)
  else
    @users = []
  end

  respond_to do |format|
    format.json { render json: @users.map { |user| { id: user.id, email: user.email } } }
  end
end
```

### Example Route

```ruby
resources :users, only: [:index] do
  collection do
    get :search
  end
end
```

## Features

- **Debounced Search**: 300ms delay to prevent excessive API calls
- **Keyboard Navigation**: Arrow keys, Enter, and Escape support
- **Click Outside**: Closes dropdown when clicking outside
- **Minimum Length**: Configurable minimum characters before search
- **Loading States**: Handles loading and error states gracefully
- **Accessibility**: Proper ARIA attributes and keyboard navigation

## Styling

The component uses Tailwind CSS classes and follows the existing form styling patterns. You can customize the appearance by passing additional classes via the `input_class` and `container_class` parameters.

## Examples

### Basic Usage
```erb
<%= render 'shared/typeahead', 
    form: form, 
    field_name: :user_id, 
    search_url: search_users_path,
    label_text: 'Select User' %>
```

### With Custom Styling
```erb
<%= render 'shared/typeahead', 
    form: form, 
    field_name: :category_id, 
    search_url: search_categories_path,
    label_text: 'Category',
    input_class: 'border-blue-300 focus:border-blue-500',
    container_class: 'mb-6' %>
```

### For Editing Existing Records
```erb
<%= render 'shared/typeahead', 
    form: form, 
    field_name: :assigned_user_id, 
    search_url: search_users_path,
    label_text: 'Assigned To',
    current_value: @task.assigned_user&.email,
    help_text: 'Search by email address' %>
```
