# Recently Viewed Items Feature

## Overview

This document describes the **Recently Viewed Items** feature implementation using a polymorphic join table pattern. The feature tracks user viewing history for Documents (and can be extended to other models) across all their devices.

## Architecture

The implementation uses a polymorphic association pattern with the following components:

1. **ViewedItem Model** - Polymorphic join table
2. **User Model** - Enhanced with viewing history methods
3. **Document Model** - Configured as a viewable item
4. **DocumentsController** - Tracks views automatically

## Database Schema

### ViewedItems Table

```ruby
create_table :viewed_items do |t|
  t.references :user, null: false, foreign_key: true
  t.references :viewable, polymorphic: true, null: false
  t.datetime :viewed_at
  t.timestamps
end
```

### Indexes

The table includes three strategic indexes for optimal performance:

1. **User + Timestamp Index**: `[:user_id, :viewed_at]` - For fetching a user's viewing history
2. **Viewable + Timestamp Index**: `[:viewable_type, :viewable_id, :viewed_at]` - For tracking views of specific items
3. **Unique Constraint**: `[:user_id, :viewable_type, :viewable_id]` - Ensures one record per user-item pair

## Models

### ViewedItem

```ruby
class ViewedItem < ApplicationRecord
  belongs_to :user
  belongs_to :viewable, polymorphic: true

  validates :user_id, presence: true
  validates :viewable_id, presence: true
  validates :viewable_type, presence: true
  validates :viewed_at, presence: true
  validates :user_id, uniqueness: { scope: [:viewable_type, :viewable_id] }

  scope :recent, -> { order(viewed_at: :desc) }
  scope :for_type, ->(type) { where(viewable_type: type) }
end
```

### User Model Enhancements

The User model now includes:

#### Associations

```ruby
has_many :viewed_items, dependent: :destroy
```

#### Helper Methods

**1. `recently_viewed_documents(limit: 5)`**

Returns the most recently viewed documents for the user:

```ruby
user = User.find(1)
recent_docs = user.recently_viewed_documents(limit: 10)
# Returns: ActiveRecord::Relation<Document>
```

Features:
- Returns actual Document objects (not ViewedItem records)
- Ordered by most recent view first
- Ensures unique documents only
- Efficient single-query execution with JOIN

**2. `recently_viewed(viewable_type:, limit: 5)` (Generic)**

Returns recently viewed items of any type:

```ruby
user = User.find(1)
recent_articles = user.recently_viewed(viewable_type: 'Article', limit: 5)
```

This method is designed for future extensibility when you add other viewable models.

### Document Model Enhancements

```ruby
has_many :viewed_items, as: :viewable, dependent: :destroy
```

This polymorphic association allows documents to track their views.

## Controller Implementation

### DocumentsController#show

The show action automatically tracks views for authenticated users:

```ruby
def show
  # Track view for authenticated users
  track_document_view if current_user
  
  # ... rest of the show logic
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
```

**How it works:**
1. Finds existing ViewedItem record for this user+document combination
2. If none exists, initializes a new one
3. Updates the `viewed_at` timestamp to current time
4. Saves the record (inserts or updates as needed)

This approach ensures:
- Only one record per user-document pair
- Timestamp updates on each view
- Efficient database operations (no duplicate records)

## Usage Examples

### 1. Display Recently Viewed Documents in a View

```erb
<!-- app/views/dashboard/index.html.erb -->
<h2>Recently Viewed Documents</h2>
<ul>
  <% current_user.recently_viewed_documents(limit: 5).each do |document| %>
    <li>
      <%= link_to document.title, document_path(document) %>
      <small>Viewed: <%= time_ago_in_words(document.viewed_items.find_by(user: current_user).viewed_at) %> ago</small>
    </li>
  <% end %>
</ul>
```

### 2. Get Viewing Statistics

```ruby
# Get total views for a document
document = Document.find(1)
total_views = document.viewed_items.count

# Get unique viewers for a document
unique_viewers = document.viewed_items.distinct.count(:user_id)

# Get when a specific user last viewed a document
last_viewed = ViewedItem.find_by(user: current_user, viewable: document)&.viewed_at
```

### 3. Get All Viewing History for a User

```ruby
user = User.find(1)
all_viewed = user.viewed_items.recent
# Returns ViewedItem records ordered by viewed_at DESC
```

### 4. Advanced Queries

```ruby
# Get documents viewed in the last week
user.viewed_items
    .where(viewable_type: 'Document')
    .where('viewed_at > ?', 1.week.ago)
    .includes(:viewable)
    .map(&:viewable)

# Get most popular documents (viewed by most users)
Document.joins(:viewed_items)
        .group('documents.id')
        .order('COUNT(viewed_items.id) DESC')
        .limit(10)
```

## Extending to Other Models

To make other models viewable (e.g., Articles, Posts), follow these steps:

### 1. Add the Polymorphic Association

```ruby
# app/models/article.rb
class Article < ApplicationRecord
  has_many :viewed_items, as: :viewable, dependent: :destroy
end
```

### 2. Track Views in the Controller

```ruby
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def show
    @article = Article.find(params[:id])
    track_article_view if current_user
  end

  private

  def track_article_view
    viewed_item = ViewedItem.find_or_initialize_by(
      user: current_user,
      viewable: @article
    )
    viewed_item.viewed_at = Time.current
    viewed_item.save
  end
end
```

### 3. Add Convenience Method to User Model (Optional)

```ruby
# app/models/user.rb
def recently_viewed_articles(limit: 5)
  Article.joins(:viewed_items)
         .where(viewed_items: { user_id: id })
         .order('viewed_items.viewed_at DESC')
         .distinct
         .limit(limit)
end
```

Or use the generic method:

```ruby
user.recently_viewed(viewable_type: 'Article', limit: 5)
```

## Performance Considerations

### Indexes

The migration includes three composite indexes to optimize common queries:

1. `[:user_id, :viewed_at]` - Fast user history retrieval
2. `[:viewable_type, :viewable_id, :viewed_at]` - Fast item view tracking
3. `[:user_id, :viewable_type, :viewable_id]` - Unique constraint and fast lookups

### Query Optimization

The `recently_viewed_documents` method uses:
- `JOIN` instead of N+1 queries
- `DISTINCT` to prevent duplicates
- Index-optimized ORDER BY on `viewed_at`
- `LIMIT` to control result set size

### Scaling Considerations

For high-traffic applications, consider:

1. **Caching**: Cache recently viewed lists in Redis
   ```ruby
   def recently_viewed_documents(limit: 5)
     Rails.cache.fetch("user:#{id}:recent_docs", expires_in: 5.minutes) do
       Document.joins(:viewed_items)
               .where(viewed_items: { user_id: id })
               .order('viewed_items.viewed_at DESC')
               .distinct
               .limit(limit)
               .to_a
     end
   end
   ```

2. **Background Jobs**: Track views asynchronously for better response times
   ```ruby
   TrackViewJob.perform_later(user_id: current_user.id, 
                              viewable_type: 'Document', 
                              viewable_id: @document.id)
   ```

3. **Archiving**: Archive old ViewedItem records after N days
   ```ruby
   # lib/tasks/cleanup.rake
   task cleanup_old_views: :environment do
     ViewedItem.where('viewed_at < ?', 90.days.ago).delete_all
   end
   ```

## Testing

### Model Tests

```ruby
# spec/models/viewed_item_spec.rb
RSpec.describe ViewedItem, type: :model do
  it { should belong_to(:user) }
  it { should belong_to(:viewable) }
  it { should validate_presence_of(:user_id) }
  it { should validate_presence_of(:viewable_id) }
  it { should validate_presence_of(:viewable_type) }
  it { should validate_presence_of(:viewed_at) }

  describe 'uniqueness validation' do
    let(:user) { create(:user) }
    let(:document) { create(:document) }

    it 'prevents duplicate user-viewable combinations' do
      create(:viewed_item, user: user, viewable: document)
      duplicate = build(:viewed_item, user: user, viewable: document)
      expect(duplicate).not_to be_valid
    end
  end
end

# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  describe '#recently_viewed_documents' do
    let(:user) { create(:user) }
    let!(:doc1) { create(:document) }
    let!(:doc2) { create(:document) }
    let!(:doc3) { create(:document) }

    before do
      create(:viewed_item, user: user, viewable: doc1, viewed_at: 3.days.ago)
      create(:viewed_item, user: user, viewable: doc2, viewed_at: 1.day.ago)
      create(:viewed_item, user: user, viewable: doc3, viewed_at: 2.days.ago)
    end

    it 'returns documents ordered by most recent view' do
      recent = user.recently_viewed_documents(limit: 3)
      expect(recent).to eq([doc2, doc3, doc1])
    end

    it 'respects the limit parameter' do
      recent = user.recently_viewed_documents(limit: 2)
      expect(recent.count).to eq(2)
    end

    it 'returns distinct documents' do
      # Update the viewed_at timestamp for doc2
      ViewedItem.find_by(user: user, viewable: doc2).update(viewed_at: Time.current)
      
      recent = user.recently_viewed_documents(limit: 3)
      expect(recent.count).to eq(3)
      expect(recent.uniq.count).to eq(3)
    end
  end
end
```

### Controller Tests

```ruby
# spec/controllers/documents_controller_spec.rb
RSpec.describe DocumentsController, type: :controller do
  describe 'GET #show' do
    let(:user) { create(:user) }
    let(:document) { create(:document) }

    context 'when user is logged in' do
      before { sign_in user }

      it 'tracks the view' do
        expect {
          get :show, params: { id: document.id }
        }.to change { ViewedItem.count }.by(1)
      end

      it 'updates the viewed_at timestamp on subsequent views' do
        create(:viewed_item, user: user, viewable: document, viewed_at: 1.hour.ago)
        
        expect {
          get :show, params: { id: document.id }
        }.not_to change { ViewedItem.count }
        
        viewed_item = ViewedItem.find_by(user: user, viewable: document)
        expect(viewed_item.viewed_at).to be_within(1.second).of(Time.current)
      end
    end

    context 'when user is not logged in' do
      it 'does not track the view' do
        expect {
          get :show, params: { id: document.id }
        }.not_to change { ViewedItem.count }
      end
    end
  end
end
```

## Security Considerations

1. **Authorization**: The feature respects Rails' authorization. Only authenticated users can track views.

2. **Privacy**: Consider adding user preferences to opt-out of tracking:
   ```ruby
   # app/models/user.rb
   def track_views?
     # Add a boolean column to users table
     allow_view_tracking?
   end
   
   # app/controllers/documents_controller.rb
   def track_document_view
     return unless current_user.track_views?
     # ... rest of the tracking logic
   end
   ```

3. **Data Retention**: Implement a policy for how long to retain viewing history.

## Future Enhancements

1. **View Count Cache**: Add a counter cache to avoid COUNT queries
2. **Trending Items**: Track views over time windows (daily, weekly, monthly)
3. **Recommendations**: Use viewing history for personalized recommendations
4. **Analytics Dashboard**: Build reports on viewing patterns
5. **Cross-Device Sync**: Already supported via user_id association
6. **View Duration**: Track how long users spend viewing items

## Migration File

Location: `db/migrate/YYYYMMDDHHMMSS_create_viewed_items.rb`

```ruby
class CreateViewedItems < ActiveRecord::Migration[7.2]
  def change
    create_table :viewed_items do |t|
      t.references :user, null: false, foreign_key: true
      t.references :viewable, polymorphic: true, null: false
      t.datetime :viewed_at

      t.timestamps
    end

    # Add composite index for efficient queries by user
    add_index :viewed_items, [:user_id, :viewed_at]
    
    # Add composite index for efficient queries by viewable
    add_index :viewed_items, [:viewable_type, :viewable_id, :viewed_at]
    
    # Add unique index to ensure one view record per user-viewable combination
    add_index :viewed_items, [:user_id, :viewable_type, :viewable_id], 
              unique: true, 
              name: 'index_viewed_items_on_user_and_viewable'
  end
end
```

## Summary

The Recently Viewed Items feature is now fully implemented and provides:

✅ **Polymorphic Design** - Easily extensible to other models
✅ **Efficient Queries** - Optimized with strategic indexes
✅ **Automatic Tracking** - Views tracked automatically in controller
✅ **User-Friendly API** - Simple methods to retrieve viewing history
✅ **Cross-Device Support** - Works across all user devices via user_id
✅ **Timestamp Updates** - Timestamps update on each view
✅ **No Duplicates** - Unique constraint prevents duplicate records
✅ **Database Integrity** - Foreign keys and validations ensure data quality

The feature is production-ready and follows Rails best practices.

