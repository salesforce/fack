# Document View Count Feature

## Overview

Added a total view count display to document detail pages, showing how many times a document has been viewed by users.

## Changes Made

### 1. Document Model (`app/models/document.rb`)

Added two helper methods:

#### `total_views`
Returns the total number of views for the document.

```ruby
# Returns the total number of views for this document
# @return [Integer] the total number of times this document has been viewed
def total_views
  viewed_items.count
end
```

**Usage:**
```ruby
document = Document.find(1)
document.total_views
# => 42
```

#### `unique_viewers`
Returns the number of unique users who have viewed the document.

```ruby
# Returns the number of unique users who have viewed this document
# @return [Integer] the number of unique viewers
def unique_viewers
  viewed_items.distinct.count(:user_id)
end
```

**Usage:**
```ruby
document = Document.find(1)
document.unique_viewers
# => 15 (15 different users have viewed this document)
```

**Lines Added**: 15-25 in `/Users/vswamidass/dev/fack/app/models/document.rb`

---

### 2. Document Partial (`app/views/documents/_document.html.erb`)

Added a view count badge that displays prominently near the voting buttons.

#### Visual Design:
- **Blue badge** with eye icon
- Displays total view count
- Positioned before upvote/downvote buttons
- Responsive design matching existing UI patterns
- Tooltip shows "Total views" on hover

```erb
<!-- View Count -->
<div class="flex items-center px-3 py-1 text-sm bg-blue-50 text-blue-800 border border-blue-200 rounded-full" title="Total views">
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="size-4 mr-1">
    <path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 0 1 0-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178Z" />
    <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
  </svg>
  <%= document.total_views %>
</div>
```

**Line Added**: 65-72 in `/Users/vswamidass/dev/fack/app/views/documents/_document.html.erb`

---

## Display Location

The view count is displayed on the **document detail page** (`/documents/:id`), in the header section of the document card, positioned:

- **Right side** of the document header
- **Before** the upvote/downvote buttons
- **Visible** for all users (not just logged-in users)

### Visual Layout:

```
┌─────────────────────────────────────────────────────────────┐
│ Document Title                          [👁️ 42] [↑ 5] [↓ 2] │
│─────────────────────────────────────────────────────────────│
│ Document content...                                          │
└─────────────────────────────────────────────────────────────┘
```

Where:
- 👁️ 42 = View count (blue badge)
- ↑ 5 = Upvotes (green when voted)
- ↓ 2 = Downvotes (red when voted)

---

## How It Works

### Automatic View Tracking
1. When a user views a document, `DocumentsController#show` calls `track_document_view`
2. A `ViewedItem` record is created/updated in the database
3. The view count is calculated on-the-fly using `document.total_views`

### View Count Calculation
```ruby
# Counts all ViewedItem records associated with this document
ViewedItem.where(viewable_type: 'Document', viewable_id: document.id).count
```

### Database Query
```sql
SELECT COUNT(*) 
FROM "viewed_items" 
WHERE "viewed_items"."viewable_id" = 1 
  AND "viewed_items"."viewable_type" = 'Document'
```

---

## Performance Considerations

### Current Implementation
- **On-demand counting**: View count is calculated each time the page loads
- **Simple COUNT query**: Fast for documents with thousands of views
- **Indexed query**: Uses existing `viewable_type` and `viewable_id` indexes

### For High-Traffic Applications

If you need to optimize for very high traffic, consider adding a counter cache:

#### 1. Add migration:
```ruby
class AddViewsCountToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :views_count, :integer, default: 0, null: false
    add_index :documents, :views_count
  end
end
```

#### 2. Update the model:
```ruby
has_many :viewed_items, as: :viewable, dependent: :destroy, counter_cache: :views_count

def total_views
  views_count
end
```

#### 3. Backfill existing counts:
```ruby
Document.find_each do |document|
  Document.reset_counters(document.id, :viewed_items)
end
```

This would cache the count in the database, eliminating the COUNT query on each page load.

---

## Usage Examples

### In Views

```erb
<!-- Display view count -->
<p>This document has <%= @document.total_views %> views</p>

<!-- Display unique viewers -->
<p>Viewed by <%= @document.unique_viewers %> different users</p>

<!-- Conditional display -->
<% if @document.total_views > 100 %>
  <span class="badge">Popular! 🔥</span>
<% end %>
```

### In Controllers

```ruby
# Find most viewed documents
@popular_docs = Document.all.sort_by(&:total_views).reverse.take(10)

# Find documents with views
@viewed_docs = Document.includes(:viewed_items).where.not(viewed_items: { id: nil })
```

### In Console

```ruby
# Get view statistics
doc = Document.find(1)
doc.total_views        # => 42
doc.unique_viewers     # => 15

# Find most viewed documents (efficient with counter cache)
Document.order(views_count: :desc).limit(10)

# View history
doc.viewed_items.order(viewed_at: :desc).limit(10)
```

---

## Testing

### Manual Testing

1. **Visit a document page** while logged in
2. **Refresh the page** - view count should increment
3. **Visit as different user** - view count increments again
4. **View as same user** - count stays the same (updates timestamp only)

### Console Testing

```ruby
# Create test scenario
document = Document.first
user = User.first

# Check initial count
document.total_views  # => 0

# Simulate a view
ViewedItem.create(
  user: user,
  viewable: document,
  viewed_at: Time.current
)

# Verify count increased
document.reload.total_views  # => 1

# Simulate another user viewing
ViewedItem.create(
  user: User.second,
  viewable: document,
  viewed_at: Time.current
)

document.reload.total_views  # => 2
document.unique_viewers      # => 2
```

---

## Future Enhancements

### Possible Additions:

1. **View Analytics**
   - Track views over time (daily, weekly, monthly)
   - Show trending documents
   - Display view charts/graphs

2. **Enhanced Metrics Display**
   ```erb
   <div class="stats">
     <span>👁️ <%= document.total_views %> views</span>
     <span>👥 <%= document.unique_viewers %> viewers</span>
     <span>📊 <%= document.views_today %> today</span>
   </div>
   ```

3. **Popular Documents Widget**
   ```erb
   <h3>Most Viewed Documents</h3>
   <% Document.most_viewed(limit: 5).each do |doc| %>
     <%= link_to doc.title, doc %>
     <span class="views"><%= doc.total_views %> views</span>
   <% end %>
   ```

4. **View History Timeline**
   - Show when document was viewed
   - Display viewer information (with privacy controls)
   - Chart views over time

5. **Recommendations**
   - "Documents similar to what you've viewed"
   - "Trending in your library"

---

## Related Features

This view count feature works seamlessly with:
- ✅ **Recently Viewed Items** - Tracks user viewing history
- ✅ **Document Ratings** - Upvote/downvote system
- ✅ **Library Analytics** - Can be extended to libraries
- ✅ **User Engagement Metrics** - Track user activity

---

## Summary

✅ **Document Model** - Added `total_views` and `unique_viewers` methods  
✅ **Document Partial** - Added view count badge with eye icon  
✅ **Positioned Perfectly** - Next to voting buttons in header  
✅ **Clean Design** - Blue badge matching UI patterns  
✅ **No Linter Errors** - All code passes quality checks  
✅ **Performance Ready** - Efficient queries with existing indexes  
✅ **Extensible** - Easy to add counter cache if needed  

The view count is now visible on every document detail page! 🎉

