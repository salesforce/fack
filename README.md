# What is Fack?
Fack answers frequently asked questions using Generative AI.
Here is an example:
![question](public/example-question.png)

## Use Cases
At Salesforce, we use fack for internal Q&A.  We feed documents and summarized slack threads to fack.  
In some channels, we see up to 40% of our support requests receive helpful answers from fack.

We are experiementing with other use cases like:
- Improving incident resolution by quickly finding suggested solutions
- Translating between query languages

Almost any RAG-based solution can be quickly implmented in fack.

## Why is it Called Fack?
The term FAQ, or Frequently Asked Questions, is often pronounced [fack](https://english.stackexchange.com/questions/4165/what-is-the-commonly-accepted-pronunciation-of-faq).

## Inspiration
Fack is built on the principles outlined by OpenAI for question/answer applications in documents like:
- https://platform.openai.com/docs/tutorials/web-qa-embeddings
- https://github.com/openai/openai-cookbook/blob/main/examples/Question_answering_using_embeddings.ipynb


## Benefits of Fack

### APIs
Reuse your documents across multiple systems.
Need a Q/A interface? Done.  Need to provide answers in a chat bot? Done.

### Shared AI Knowledge
Working with LLMs is deceptively complex.
Vector embeddings, token counting, effective prompting all require thought to make effective use of LLMs.
By having a shared service, you can have one service to manage retrieval-augmented search and ask queries.

### Deduplication
When managing thousands of documents, managing documents is difficult.  Are there duplicates?  What are the groups of documents?

### Document Grouping
All documents are not equal.  You have different groups within your company and organization.  Different teams need to manage their documents.
Visibilty may be an issue.

# Principles
1. __Open Source__.  This should be reusable as far as possible.  Nothing in the tool should be hardcoded to Salesforce or any team in Salesforce.  The tool has clear deployment and development instructions.
2. __API first__.  The end user interactions will likely happen through other bots and applications.  So, the service should be API first.
3. __Multi-tenant__.  Different teams should be able to share the same technology, without mixing their data.

# Design

## Data Flow
![Diagram](public/arch-diagram.png)

## Why Search is Better than Fine-tuning
The [OpenAI doc](https://cookbook.openai.com/examples/question_answering_using_embeddings#why-search-is-better-than-fine-tuning) outlines the reasons why search/retrieval is typically better than fine-tuning.
- "Fine-tuning is better suited to teaching specialized tasks or styles, and is less reliable for factual recall."
- Search/retrival enables more reliable source citation.  We can provide specific documents with urls/names to the GPT and require references to the documents used for answering the question.  In fine-tuning, the original source is most likely lost or unavailable.


# Developers

## Requirements
- Rails 7
- Ruby 3+
- Postgres with pg_vector support

## Running Locally
1. Clone the repo
```
git clone https://github.com/salesforce/fack.git
```
2. Install dependencies
```
bundle
```
3. Database creation/migration
```
rails db:create
rails db:migrate
TEST_PASSWORD='<your_password>' rails db:seed
```
Set TEST_PASSWORD to an 8+ character string with a number, uppercase letter and special character.  '2Testai!' as an example.

4. Create a .env file in the root directory.  Provide these variables.
```
# LLM AUTH.  You need to provide an OpenAI Key or a Salesforce Einstein Org
## OpenAI key from https://platform.openai.com/account/api-keys
OPENAI_API_KEY=<openai token>

## OR Salesforce Einstein credentials from your Org
SALESFORCE_CONNECT_ORG_URL=
SALESFORCE_CONNECT_CLIENT_ID=
SALESFORCE_CONNECT_CLIENT_SECRET=
SALESFORCE_CONNECT_USERNAME=
SALESFORCE_CONNECT_PASSWORD=

# i.e. https://fack.yourdomain.com or http://localhost:3000 Used to generate URLs in the answers.
ROOT_URL=

## SAML/SSO Metadata URL (OPTIONAL)
SSO_METADATA_URL=

## Max number of document tokens to send to the GPT prompt. (OPTIONAL)
MAX_PROMPT_DOC_TOKENS=

## Max tokens to send in the prompt (OPTIONAL, DEFAULT 10,000)
EGPT_MAX_TOKENS=

## Which OpenAI model to use. (OPTIONAL)
EGPT_GEN_MODEL=

## Disable Password Login if you have SSO enabled.  (OPTIONAL)
DISABLE_PASSWORD_LOGIN=<true/false>
```

5. Open a new terminal and start the Background job for AI Calls
```
rake jobs:work
```

You should see:
[Worker(host:host.something.com pid:89737)] Starting job worker

6. Start web server
```
rails s
```

Open http://localhost:3000 and login with admin@fack.com as the username and the TEST_PASSWORD you set earlier.

## Testing
```
bundle exec rspec
```

The tests are located under the `spec` directory.


# Usage

# UI
Coming soon

# API

------------------------------------------------------------------------------------------

#### Questions

<details>
 <summary><code>POST</code> <code><b>/api/v1/questions</b></code> <code>Create a new Question (Ask AI for answer)</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | question  |  required | text                    | The question to ask of the documentation   |
> | library_ids  |  optional | comma separated ids (reference to library)            | The libraries to limit the answers   |    


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Question created successfully`                                     |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```javascript
> curl -X POST -H "Authorization: Bearer <token>" -H "Content-Type: application/json" -d '{"question": { "question" : "how do i setup falcon?"}}' http://localhost:3000/api/v1/questions
> ```

> ```javascript
>{
>   "id": 226,
>   "question": "how do i setup falcon?",
>   "status":"generating",
>   "answer": "# ANSWER\nTo set up Falcon, you need to install the Falcon CLI. Here are the steps to install the Falcon CLI:\n\n1. For macOS users, install the Falcon CLI with brew:\n   ```\n   brew tap sfdc-falcon/cli git[@git.soma.salesforce.com:sfdc-falcon/>homebrew-cli.git](https://git.soma.salesforce.com/git.soma.salesforce.com:sfdc-falcon/homebrew-cli.git)\n   brew install falcon-cli\n   ```\n\n2.  For Linux users, install the Falcon CLI with `curl`:\n   ```\n   curl -sSL https://sfdc.co/get-falcon-cli | bash\n   ```\n\n3. Verify that you've successfully installed the CLI by logging in:\n   ```\n   falcon login\n   ```\n\nYou can find more information about setting up the Falcon CLI in the [Install the Falcon Command Line Interface (CLI)](https://git.soma.salesforce.com/tech-enablement/falcon-paved-path/blob/main/install-falcon-cli.md) document.\n\n# SOURCES\n- [Install the Falcon Command Line Interface (CLI)](https://git.soma.salesforce.com/tech-enablement/falcon-paved-path/blob/main/install-falcon-cli.md)",
>   "created_at": "2023-11-03T17:28:43.625Z",
>   "updated_at": "2023-11-03T17:28:43.625Z",
>   "url": "http://localhost:3000/questions/226.json"
>}
> ```

</details>
    
    
<details>
 <summary><code>GET</code> <code><b>/api/v1/questions/_id_</b></code> <code>Retrieve Question</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|


##### Responses

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | question  |   | text                    | The question to ask of the documentation   |
> | status  |   | pending, generating, generated, failed         | The status of the generated answer.  Poll every 5 seconds until the status is generated or failed.   |    
> | able_to_answer  |   |  boolean        | Was the GPT able to generate an answer? (true/false)  |    
> | url        |      | text       | URL to access the question                          |
> | answer        |      | text       | Answer to the question                          |

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `text/plain;charset=UTF-8`        |                                     |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```javascript
> curl -X GET -H "Authorization: Bearer <token>"  http://localhost:3000/api/v1/questions/226
> ```

> ```javascript
>{
>   "id": 226,
>   "question": "how do i setup falcon?",
>   "status":"generated",
>   "answer": "# ANSWER\nTo set up Falcon, you need to install the Falcon CLI. Here are the steps to install the Falcon CLI:\n\n1. For macOS users, install the Falcon CLI with brew:\n   ```\n   brew tap sfdc-falcon/cli git[@git.soma.salesforce.com:sfdc-falcon/>homebrew-cli.git](https://git.soma.salesforce.com/git.soma.salesforce.com:sfdc-falcon/homebrew-cli.git)\n   brew install falcon-cli\n   ```\n\n2.  For Linux users, install the Falcon CLI with `curl`:\n   ```\n   curl -sSL https://sfdc.co/get-falcon-cli | bash\n   ```\n\n3. Verify that you've successfully installed the CLI by logging in:\n   ```\n   falcon login\n   ```\n\nYou can find more information about setting up the Falcon CLI in the [Install the Falcon Command Line Interface (CLI)](https://git.soma.salesforce.com/tech-enablement/falcon-paved-path/blob/main/install-falcon-cli.md) document.\n\n# SOURCES\n- [Install the Falcon Command Line Interface (CLI)](https://git.soma.salesforce.com/tech-enablement/falcon-paved-path/blob/main/install-falcon-cli.md)",
>   "created_at": "2023-11-03T17:28:43.625Z",
>   "updated_at": "2023-11-03T17:28:43.625Z",
>   "url": "http://localhost:3000/questions/226.json"
>}
> ```

</details>

<details>
<summary><code>GET</code> <code><b>/api/v1/questions</b></code> <code>List Questions</code></summary>

##### Parameters

| name  | type     | data type | description                     |
|-------|----------|-----------|---------------------------------|
| page  | optional | integer   | The page number to retrieve. Defaults to 1. |

##### Responses

| name      | type | data type | description                                                    |
|-----------|------|-----------|----------------------------------------------------------------|
| questions |      | array     | An array of question objects, each containing question details |

Each object in the `questions` array includes:

| name       | type | data type  | description                                         |
|-------------|----------|-----------|----------------------------------------------|
| id          |          | integer   | The ID of the question                       |
| question    |          | text      | The content of the question                  |
| status      |          | text      | The status of the question (e.g., generated) |
| answer      |          | text      | The answer to the question                   |
| url         |          | text      | URL to access the question                   |
| created_at  |          | datetime  | The creation date and time of the question   |
| updated_at  |          | datetime  | The last update date and time of the question|


| http code | content-type                 | response                    |
|-----------|------------------------------|-----------------------------|
| `200`     | `application/json`           | JSON array of questions     |
| `400`     | `application/json`           | `{"code":"400","message":"Bad Request"}` |

##### Example cURL

>```
>curl -X GET -H "Authorization: Bearer <token>" "http://localhost:3000/api/v1/questions"
>```

>```javascript
> {
>   "questions": [
>     {
>       "id": 226,
>       "question": "how do i setup a new service?",
>       "status": "generated",
>       "answer": "# ANSWER\nTo set up ...",
>       "created_at": "2023-11-03T17:28:43.625Z",
>       "updated_at": "2023-11-03T17:28:43.625Z",
>       "url": "http://localhost:3000/questions/226.json"
>     },
>     {
>       "id": 227,
>       "question": "how do i use gen ai?",
>       "status": "generated",
>       "answer": "# ANSWER\n...",
>       "url": "http://localhost:3000/questions/227.json",
>       "created_at": "2023-11-14T01:55:11.731Z",
>       "updated_at": "2024-03-01T22:58:55.865Z"
>     }
>   ]
> }
>```
</details>
     
#### Documents
     
<details>
 <summary><code>POST</code> <code><b>/api/v1/documents</b></code> <code>Create a new Document</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | document  |  required | text                    | The content of the document   |
> | library_id  |  required | text | The ID of the library to which this document will be added            |  
> | external_id  |  optional | text          | A unique ID provided by the client. If a POST request includes the same external_id as an existing record, the record will be updated instead of created. |    


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Document created successfully`                                     |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```javascript
>  curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -d '{"document":"Document Content", "library_id":"your_library_id", "external_id":"optional_unique_id"}' http://localhost:3000/api/v1/documents
> ```

</details>
    
    
<details>
 <summary><code>GET</code> <code><b>/api/v1/documents/_id_</b></code> <code>Retrieve Document</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `text/plain;charset=UTF-8`        |                                     |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```
>  curl -X GET -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/documents/<id>
> ```

> ```
> {
>  "id": 1,
>  "document": "# QUESTION\nHow do I use gen ai?\n\n# ANSWER\n...",
>  "url": "http://localhost:3000/documents/1",
>  "length": 97,
>  "created_at": "2023-11-14T01:55:11.731Z",
>  "updated_at": "2024-03-01T22:58:55.865Z"
> }
> ```
</details>

<details>
<summary><code>GET</code> <code><b>/api/v1/documents</b></code> <code>List Documents</code></summary>

##### Parameters

| name  | type     | data type | description                     |
|-------|----------|-----------|---------------------------------|
| page  | optional | integer   | The page number to retrieve. Defaults to 1. |

##### Responses

| name      | type | data type | description                                                    |
|-----------|------|-----------|----------------------------------------------------------------|
| documents |      | array     | An array of document objects, each containing document details |

Each object in the `documents` array includes:

| name       | type | data type  | description                                         |
|------------|------|------------|-----------------------------------------------------|
| id         |      | integer    | The ID of the document                              |
| document   |      | text       | The content of the document                         |
| url        |      | text       | URL to access the document                          |
| created_at |      | datetime   | The creation date and time of the document          |
| updated_at |      | datetime   | The last update date and time of the document       |

| http code | content-type                 | response                    |
|-----------|------------------------------|-----------------------------|
| `200`     | `application/json`           | JSON array of documents     |
| `400`     | `application/json`           | `{"code":"400","message":"Bad Request"}` |

##### Example cURL

>```
>curl -X GET -H "Authorization: Bearer <token>" "http://localhost:3000/api/v1/documents?page=1"
>```

>```javascript
>{
>  "documents": [
>    {
>      "id": 1,
>      "document": "# QUESTION\nHow do I use gen ai?\n\n# ANSWER\nThere is no direct answer provided in the conversation.",
>      "url": "http://localhost:3000/documents/1",
>      "created_at": "2023-11-14T01:55:11.731Z",
>      "updated_at": "2024-03-01T22:58:55.865Z"
>    },
>    {
>      "id": 2,
>      "document": "# QUESTION\nHow do I integrate API?\n\n# ANSWER\nTo integrate an API, first identify the API you need to integrate with...",
>      "url": "http://localhost:3000/documents/2",
>      "created_at": "2023-12-14T02:55:11.731Z",
>      "updated_at": "2024-01-02T23:58:55.865Z"
>    }
>    ...
>  ]
>}
>```
</details>

     
#### Libraries
     
<details>
 <summary><code>POST</code> <code><b>/api/v1/libraries</b></code> <code>Create a new Library</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|
> | name  |  required | text                    | The name of the library   | 


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `201`         | `text/plain;charset=UTF-8`        | `Library created successfully`                                     |
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```javascript
> curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer <token>" -d '{"name":"Library Name"}' http://localhost:3000/api/v1/libraries
> ```

</details>
    
    
<details>
 <summary><code>GET</code> <code><b>/api/v1/library/_id_</b></code> <code>Retrieve Library</code></summary>

##### Parameters

> | name      |  type     | data type               | description                                                           |
> |-----------|-----------|-------------------------|-----------------------------------------------------------------------|


##### Responses

> | http code     | content-type                      | response                                                            |
> |---------------|-----------------------------------|---------------------------------------------------------------------|
> | `200`         | `text/plain;charset=UTF-8`        ||
> | `400`         | `application/json`                | `{"code":"400","message":"Bad Request"}`                            |

##### Example cURL

> ```
> curl -X GET -H "Authorization: Bearer <token>" http://localhost:3000/api/v1/libraries/<id>
> ```

>```javascript
>{
>  "id": 1,
>  "name": "My Docs",
>  "created_at": "2023-11-15T20:17:25.665Z",
>  "updated_at": "2023-12-01T19:59:44.618Z",
>  "url": "http://localhost:3000/libraries/1"
>}
>```

</details>


<details>
<summary><code>GET</code> <code><b>/api/v1/libraries</b></code> <code>List Libraries</code></summary>

##### Parameters

| name  | type     | data type | description                     |
|-------|----------|-----------|---------------------------------|
| page  | optional | integer   | The page number to retrieve. Defaults to 1. |

##### Responses

| name      | type | data type | description                                                    |
|-----------|------|-----------|----------------------------------------------------------------|
| libraries |      | array     | An array of library objects, each containing library details |

Each object in the `documents` array includes:

| name       | type | data type  | description                                         |
|------------|------|------------|-----------------------------------------------------|
| id         |      | integer    | The ID of the library                              |
| name        |      | text       | Name of the library                          |
| created_at |      | datetime   | The creation date and time of the library          |
| updated_at |      | datetime   | The last update date and time of the library       |

| http code | content-type                 | response                    |
|-----------|------------------------------|-----------------------------|
| `200`     | `application/json`           | JSON array of libraries     |
| `400`     | `application/json`           | `{"code":"400","message":"Bad Request"}` |

##### Example cURL

>```
>curl -X GET -H "Authorization: Bearer <token>" "http://localhost:3000/api/v1/libraries"
>```

>```
>{
>  "libraries": [
>    {
>      "id": 1,
>      "name": "My Library",
>      "created_at": "2023-11-14T01:55:11.731Z",
>      "updated_at": "2024-03-01T22:58:55.865Z"
>    },
>    {
>      "id": 2,
>      "name": "My Second Library",
>      "created_at": "2023-01-14T01:55:11.731Z",
>      "updated_at": "2023-03-01T22:58:55.865Z"
>    },
>    ...
>  ]
>}
>```
</details>


# Guides

## Setup SSO
1. Get the SSO Metadata URL from your SSO provider.  i.e. https://company.okta.com/app/xyz/sso/saml/metadata
2. Set the SSO_METADATA_URL to the url from previous step in your .env file or environment.
3. Restart your app.
4. Optionally, disable username/password login with DISABLE_PASSWORD_LOGIN=true environment variable.

## Importing Your Documents (DRAFT)

### 1. Choose or Create a Library
The library is a collection of similar documents.  For example:
- Infrastructure
- Dev Docs
- Onboarding

The library allows document owners to keep their documents separate from each other.  It also enables more selective question/answers.

#### Existing Library
1. Go to /libraries in the UI
2. Locate the library you want.
3. Note the id in the URL.

#### Creating a Library
1. Go to /libraries in the UI
2. Click "New Library" button.
3. Provide a name and save.
Get the id of the library from the URL.

### 2. Get an API Token
1. Open /api_tokens in the ui.
2. Create a token.

### 3. Locate the Directory with your Documents
You can clone your doc repo or have an directory anywhere on your computer.

### 4. Run the import script
Set the variables in .env
```
IMPORT_API_TOKEN=<your token>
ROOT_URL=<root url>  # "http://localhost:3000" if you are testing locally.
```

```
./import.sh -u http://localhost:3000 -d <path_to_your_docs> -l <library_id>
```

### 5. Verify and Test
1. Go to /libraries and click on the library you used.
2. See if the documents from your import are listed.
