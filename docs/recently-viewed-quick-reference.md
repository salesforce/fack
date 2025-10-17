# Recently Viewed Items - Quick Reference

## Quick Start

### Get Recently Viewed Documents

```ruby
# In a controller or view with current_user
recent_docs = current_user.recently_viewed_documents(limit: 5)
```

### Display in a View (ERB)

```erb
<h3>Recently Viewed</h3>
<ul>
  <% current_user.recently_viewed_documents(limit: 5).each do |doc| %>
    <li><%= link_to doc.title, document_path(doc) %></li>
  <% end %>
</ul>
```

### Track a View Manually

```ruby
ViewedItem.find_or_initialize_by(
  user: current_user,
  viewable: @document
).tap do |item|
  item.viewed_at = Time.current
  item.save
end
```

## Common Queries

### User's Viewing History

```ruby
user = User.find(1)

# Get recently viewed documents (returns Document objects)
user.recently_viewed_documents(limit: 10)

# Get all viewed items (returns ViewedItem objects)
user.viewed_items.recent

# Get documents viewed today
user.viewed_items
    .where(viewable_type: 'Document')
    .where('viewed_at > ?', Time.current.beginning_of_day)
    .includes(:viewable)
    .map(&:viewable)
```

### Document Viewing Statistics

```ruby
document = Document.find(1)

# Total views
document.viewed_items.count

# Unique viewers
document.viewed_items.distinct.count(:user_id)

# Recent viewers (last 7 days)
document.viewed_items
        .where('viewed_at > ?', 7.days.ago)
        .distinct
        .count(:user_id)

# When a specific user last viewed it
document.viewed_items.find_by(user_id: user.id)&.viewed_at
```

### Popular Documents

```ruby
# Most viewed documents (all time)
Document.joins(:viewed_items)
        .group('documents.id')
        .order('COUNT(viewed_items.id) DESC')
        .limit(10)

# Most viewed documents (last 7 days)
Document.joins(:viewed_items)
        .where('viewed_items.viewed_at > ?', 7.days.ago)
        .group('documents.id')
        .order('COUNT(viewed_items.id) DESC')
        .limit(10)

# Most viewed by unique users
Document.joins(:viewed_items)
        .group('documents.id')
        .order('COUNT(DISTINCT viewed_items.user_id) DESC')
        .limit(10)
```

## API Methods

### User Model

| Method | Parameters | Returns | Description |
|--------|-----------|---------|-------------|
| `recently_viewed_documents` | `limit: 5` | `ActiveRecord::Relation<Document>` | Most recently viewed documents |
| `recently_viewed` | `viewable_type:, limit: 5` | `ActiveRecord::Relation` | Generic method for any viewable type |
| `viewed_items` | - | `ActiveRecord::Relation<ViewedItem>` | All viewing history |

### ViewedItem Model

| Scope/Method | Parameters | Returns | Description |
|--------------|-----------|---------|-------------|
| `recent` | - | `ActiveRecord::Relation` | Ordered by viewed_at DESC |
| `for_type` | `type` | `ActiveRecord::Relation` | Filter by viewable_type |

### Document Model

| Association | Type | Description |
|-------------|------|-------------|
| `viewed_items` | `has_many :viewed_items, as: :viewable` | All views of this document |

## Controller Pattern

### Automatic Tracking (Recommended)

```ruby
class DocumentsController < ApplicationController
  def show
    @document = Document.find(params[:id])
    track_document_view if current_user
    # ... rest of logic
  end

  private

  def track_document_view
    viewed_item = ViewedItem.find_or_initialize_by(
      user: current_user,
      viewable: @document
    )
    viewed_item.viewed_at = Time.current
    viewed_item.save
  end
end
```

### Background Job (For High Traffic)

```ruby
# app/jobs/track_view_job.rb
class TrackViewJob < ApplicationJob
  queue_as :default

  def perform(user_id:, viewable_type:, viewable_id:)
    viewed_item = ViewedItem.find_or_initialize_by(
      user_id: user_id,
      viewable_type: viewable_type,
      viewable_id: viewable_id
    )
    viewed_item.viewed_at = Time.current
    viewed_item.save
  end
end

# In controller
def show
  @document = Document.find(params[:id])
  
  if current_user
    TrackViewJob.perform_later(
      user_id: current_user.id,
      viewable_type: 'Document',
      viewable_id: @document.id
    )
  end
end
```

## Adding to Other Models

### Step 1: Add Association to Model

```ruby
class Article < ApplicationRecord
  has_many :viewed_items, as: :viewable, dependent: :destroy
end
```

### Step 2: Track in Controller

```ruby
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    track_view if current_user
  end

  private

  def track_view
    ViewedItem.find_or_initialize_by(
      user: current_user,
      viewable: @article
    ).tap do |item|
      item.viewed_at = Time.current
      item.save
    end
  end
end
```

### Step 3: Add Helper to User Model (Optional)

```ruby
def recently_viewed_articles(limit: 5)
  recently_viewed(viewable_type: 'Article', limit: limit)
end
```

## Caching Pattern (For Production)

### Cache Recently Viewed List

```ruby
# app/models/user.rb
def recently_viewed_documents(limit: 5)
  Rails.cache.fetch("user:#{id}:recent_docs:#{limit}", expires_in: 5.minutes) do
    Document.joins(:viewed_items)
            .where(viewed_items: { user_id: id })
            .order('viewed_items.viewed_at DESC')
            .distinct
            .limit(limit)
            .to_a
  end
end

# app/controllers/documents_controller.rb
def track_document_view
  viewed_item = ViewedItem.find_or_initialize_by(
    user: current_user,
    viewable: @document
  )
  viewed_item.viewed_at = Time.current
  viewed_item.save
  
  # Expire cache after saving
  Rails.cache.delete("user:#{current_user.id}:recent_docs:5")
end
```

## Database Maintenance

### Clean Up Old Records

```ruby
# Remove views older than 90 days
ViewedItem.where('viewed_at < ?', 90.days.ago).delete_all

# Or create a rake task
# lib/tasks/viewed_items.rake
namespace :viewed_items do
  desc "Clean up viewed items older than 90 days"
  task cleanup: :environment do
    deleted = ViewedItem.where('viewed_at < ?', 90.days.ago).delete_all
    puts "Deleted #{deleted} old viewed items"
  end
end

# Run with: rails viewed_items:cleanup
```

### Analyze Performance

```sql
-- Check index usage
SELECT * FROM pg_stat_user_indexes 
WHERE tablename = 'viewed_items';

-- Find slow queries
EXPLAIN ANALYZE 
SELECT documents.* 
FROM documents 
INNER JOIN viewed_items ON documents.id = viewed_items.viewable_id 
WHERE viewed_items.user_id = 1 
  AND viewed_items.viewable_type = 'Document'
ORDER BY viewed_items.viewed_at DESC 
LIMIT 5;
```

## Testing Examples

### RSpec Model Test

```ruby
RSpec.describe User, type: :model do
  describe '#recently_viewed_documents' do
    let(:user) { create(:user) }
    let!(:doc1) { create(:document) }
    let!(:doc2) { create(:document) }

    before do
      create(:viewed_item, user: user, viewable: doc1, viewed_at: 2.days.ago)
      create(:viewed_item, user: user, viewable: doc2, viewed_at: 1.day.ago)
    end

    it 'returns documents in correct order' do
      expect(user.recently_viewed_documents).to eq([doc2, doc1])
    end
  end
end
```

### RSpec Controller Test

```ruby
RSpec.describe DocumentsController, type: :controller do
  describe 'GET #show' do
    let(:user) { create(:user) }
    let(:document) { create(:document) }

    before { sign_in user }

    it 'tracks the view' do
      expect {
        get :show, params: { id: document.id }
      }.to change { ViewedItem.count }.by(1)
    end
  end
end
```

## Troubleshooting

### Views Not Being Tracked

1. Check if user is logged in: `current_user.present?`
2. Check if controller method is being called (add logging)
3. Verify database migration ran: `ViewedItem.table_exists?`
4. Check for validation errors: `viewed_item.errors.full_messages`

### Slow Queries

1. Verify indexes exist: `rails db:migrate:status`
2. Check index usage: `EXPLAIN ANALYZE <your query>`
3. Consider adding caching (see Caching Pattern above)
4. Use `.includes(:viewed_items)` to avoid N+1 queries

### Duplicate Records

The unique index should prevent duplicates. If you see duplicates:

1. Check migration ran correctly
2. Verify unique constraint exists: `\d viewed_items` in psql
3. Use `find_or_initialize_by` instead of `create` or `build`

## Performance Benchmarks

Expected query times (with proper indexes):

- Get recently viewed documents: < 10ms
- Track a view: < 5ms
- Count unique viewers: < 20ms
- Get popular documents: < 50ms (depends on total records)

## Environment Considerations

### Development
- Enable query logging: `config.active_record.verbose_query_logs = true`
- Use Bullet gem to detect N+1 queries

### Production
- Enable caching
- Consider background jobs for tracking
- Set up database query monitoring
- Implement data retention policy

## Resources

- Full Documentation: `docs/recently-viewed-items-feature.md`
- Implementation Summary: `docs/recently-viewed-implementation-summary.md`
- Migration File: `db/migrate/20251017181945_create_viewed_items.rb`
- Model File: `app/models/viewed_item.rb`

