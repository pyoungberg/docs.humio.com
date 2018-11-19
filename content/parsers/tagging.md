---
title: Tagging
aliases: ["ref/tags", "ref/tagging", "concept/tags"]
---

Tagging is an advanced topic and you only consider using tags if you need to
optimize search speeds.

Humio stores data in physical partitions called [datasources]({{< ref "datasources.md" >}}). Parsers can be configured
to assign events to a particular datasource based on the value of their fields – this is called tagging.

If tagging is done poorly and you create too many different tag combinations performance suffers.
You can read more about tags and datasources in a [blog post]https://medium.com/humio/understanding-humios-data-sources-a23db019a90f).

## Assigning Tags to Events

Parsers are responsible for assigning tags to events. The proper way of tagging an
event depends highly on how you intend to search in your repository, and therefor
most build-in parsers will not tag events at all.

Tags are always assigned based on field values. To use a field as a _tagging field_
you go to the _Settings_ -> _Tagging_ page while editing a parser. There you can
specify which fields should be used for tagging. Remember to limit yourself as
each unique tag combination will create a separate datasource and require heap memory.

Therefore it is a good idea to always only pick fields with a well-defined value space,
e.g for HTTP Access Logs a good tagging field could be the HTTP Method because
it has a limited set of possible values `GET`, `POST`, `HEAD` etc. and is something
which would be part of almost every search query.  

### Tagging and Humio's Ingest API

It is also possible to specify as part of the data sent to Humio. For instance
when using Humio's Ingest API all fields are already defined by the client and
no parsing is involved during ingest. Here it is possible to specify which tags
should be assigned as part of the message.

### Tagging and Filebeat

When shipping data via Filebeat you can add tags as part of the Filebeat configuration on the client-side.
These tags will be added to all events.

While tagging this way is possible, the recommended way to tag is to specify the
tagging fields in the parser's settings.

The only exception is the `#type` tag. The `#type` tag can be used specify parser
that should be use for ingestion when events arrives at Humio. But in general
it is a much more flexible solution to [assign parsers via ingest tokens]({{< ref "ingest-tokens.md#assign-a-parser">}}) and avoid
specifying the parser on the sender side.

## Example

Say you have an Nginx server which is sending access logs to Humio. You have also
defined the two field `method` and `secret` as tagging fields.

Lets assume that some URL contain sensitive information and you would like to
limit access to them to only a subset of your Humio users. In this case we will
say that any URL that starts with one of:

- `/transactions/`
- `/admin/`

Should be tagged as secret. Lets write the parser:

```humio
// The full accesslog parser has been left out for brevity.
... |
case {
  // CASE: Match events with a url field starting /transactions/ or /admin/
  url = "/transactions/*" OR "/admin/*" | secret := true;

  // CASE: Match all other events
  true | secret := false;
}
```

I could now create a [view]({{< ref "views.md" >}}) for the users that don't
have access rights to look at the data marked as `secret=true`.

We created a new field as part of the parsing process (tagging does not have
to be based on the fields on the input). Had I not defined `secret` as a tagging
field this would still work perfectly find. In fact i would get all the same
results for any search.

The difference is that because tagging forces the
secret data to be stored separately from non-secret data, Humio will skip all
events in the secret datasource completely when searching in the unprivileged
view (potentially making search much faster).
