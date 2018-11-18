 ---
title: Creating a Parser
weight: 200
aliases: ["ref/creating-a-parser", "parsers/json-parsers", "parsers/regexp-parsers"]
---

A parser is a piece of code that transforms incoming data into [events]({{< ref "events.md" >}}).
Humio has built-in parsers for common log format like `accesslog`, but if you need more control,
e.g. you want to extract more fields, do transformation on the data or assign [datasources]({{< ref "tagging.md">}}),
you can build your own parser.

In this guide we will go through the steps of creating a parser from scratch.

## Step 1. Creating a new parser

Go the the `Parsers` section of the repository you want to create the parser for.
Then click the `New Parser` button and give it a name. _The name of a parser is
important since it is what the API uses to uniquely identify the target parser._

{{< figure src="/pages/parsers/parser-list.png" width="90%" >}}


## Step 2. Writing a parser script

Once you have created your parser you will be presented with a code editor.

The programming language used for creating a parser is exactly the same as you
use to write queries on the search page. The main difference between writing a
parser and writing a search query is that you cannot use aggregate functions
like e.g. {{< function "groupBy" >}} as the parser acts on one event at a time.

The input data is usually single log lines or JSON objects, but could be any text format
like a multiline stack trace or CSV.

No matter what you send to Humio, the text value will be put in the
field called `@rawstring` which is the input to the parser.

{{% notice "info" %}}
__Example: Elastic Search__ When using the elastic search ingest API, the value of the field `message`
will put into the field `@rawstring` and is accessible in the parser script.
{{% /notice %}}

Let's write our first parser!

### Creating an event from incoming data

It is the parser's job to convert the data in `@rawstring` into an event.
That means the parser should:

1. Assign the special `@timestamp` and `@timezone` fields.
1. Extract additional fields that should be stored along with your event.

_The input already includes the `@rawstring` field, so there is no need to assign
that, though it is strictly possible to assign it to something other than the input._

Let's take a look at a couple of parsers and try to understand how they work.


#### Example: Parsing Log Lines {#log-lines}

Lets assume that we have a system producing log like the following two example lines:

```
2018-10-15T12:51:40+00:00 [INFO] This is an example log entry. id=123 fruit=banana
2018-10-15T12:52:42+01:30 [ERROR] Here is an error log entry. class=c.o.StringUtil fruit=pineapple
```

We want the parser to produce two events (one per line) and use the timestamp of each line as
the time at which the event occurred - i.e. assign it to the special `@timestamp` and `@timezone` fields.

To do this we could write a parser script like:

```humio
// Create field called "ts" by extracting the first part of each
// log line using a regular expression. See https://docs.humio.com/query-functions/#regex.
// The syntax `?<ts>` is called a "named group". It means whatever is matched will produce
// a field with that name - in this case a field named "ts".
/^(?<ts>\S+)/ |

// Humio expects the timestamp to be in the Millisecond Unix Time format, so next we take
// the text value we just extracted to "ts" and convert it to a number using the parseTimestamp function.
parseTimestamp("yyyy-MM-dd'T'HH:mm:ss[.SSS]XXX", field=ts)
```

Just like when querying in Humio regex literals will be applied to the `@rawstring`
field by default.

This parser just assigns the `@timestamp` and `@timezone` fields, which is the minimum you we can
do to create events from the example input above. **At this point we have a fully valid parser.** 🎉

But the two log lines actually contains more useful information, like the `INFO` and `ERROR` log severity levels.
We can extract those using another regular expression:

```humio
/^(?<ts>\S+)/ |
@timestamp := parseTimestamp("yyyy-MM-dd'T'HH:mm:ss[.SSS]XXX", field=ts) |
// The next regex matches things like [INFO] or [ERROR]
/\[(?<log_level>[^\]+])\]/ |
// The next line finds key value pairs and creates a field for each
kvParse()
```

The events will now have a field called `log_level`, and one for each `key=value`
pair in the log line, e.g. `id=123` `fruit=banana`.

#### Example: Parsing JSON {#json}

We've seen how to create a parser for unstructured log lines. Now lets try to
write aparser for JSON input. Lets use the following example input to our parser:

```json
{
  "ts": 1539602562000,
  "message": "An error occurred.",
  "host": "webserver-1"
}
{
  "ts": 1539602572100,
  "message": "User logged in.",
  "username": "sleepy",
  "host": "webserver-1"
}
```

Each object is a separate event and will be parsed separately, just like with
unstructured logs.

The JSON is accessible as a string in the field `@rawstring`. We can extract event fields
from each JSON property by using the {{< function "parseJson" >}} function.
It takes a field containing a JSON string (in this case the field `@rawstring`)
and extracts fields automatically, like e.g:

```humio
parseJson(field=@rawstring) |
@timestamp := ts |
@timezone := "Z"
```

This will result in events with fields for each property in the input JSON,
e.g. `username` and `host`, and will use the value of `ts` as the timestamp.

## Next Steps

Once you have your parser script created you can start using
it by [assigning it to Ingest Tokens]({{< ref "assigning-parsers-to-ingest-tokens.md" >}}).

You can also learn about how parsers can help speed up queries by [assigning tags]({{< ref "tagging.md" >}}).

## Reference

### Named Capture Groups {#named-groups}

Humio extracts fields using _named capture groups_ - a feature of regular expressions
that allows you to name sub-matches, e.g:

```humio
/(?<firstname>\S+)\s(?<lastname>\S+)/
```

This defines a regex that expects the input to contain names, first and last. It then extracts
the first and last names into two fields `firstname` and `lastname`. The `\S` means
any character that is not a whitespace and `\s` is a any whitespace character.


### Key-value {#key-value}

When creating a regular expression parser, you can add key-value parsing.
When you enable key-value parsing, Humio runs an extra parser on the incoming event.
This extra parser looks for key-value fields of the form:

 * `key=value`
 * `key="value"`
 * `key='value'`

So for a log line like this:

`2017-02-22T13:14:01.917+0000 [main thread] INFO  UserService -  creating new user id=123, name='john doe' email=john@doe`

 The key-value parser extracts the fields:

 * `id: 123`
 * `name: john doe`
 * `email: john@doe`

As developers start to use Humio, they can start to use the key-value pattern when logging. This gives a lot of structure to the logs in Humio.
