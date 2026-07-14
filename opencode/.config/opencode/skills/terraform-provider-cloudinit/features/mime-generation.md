# MIME Message Generation

Multipart MIME message generation for cloud-init configuration rendering.

## MIME Structure

### Standard Cloud-Init Parts

```
Content-Type: multipart/mixed; boundary="MIMEBOUNDARY"
MIME-Version: 1.0

--MIMEBOUNDARY
Content-Type: text/cloud-config
Content-Disposition: attachment; filename="cloud-config.cfg"

#cloud-config
package_update: true
...

--MIMEBOUNDARY
Content-Type: text/x-shellscript
Content-Disposition: attachment; filename="bootstrap.sh"

#!/bin/bash
echo "bootstrapping"
...

--MIMEBOUNDARY--
```

## Part Processing

### Part Model

```go
type configPartModel struct {
  ContentType types.String `tfsdk:"content_type"`
  Content     types.String `tfsdk:"content"`
  FileName    types.String `tfsdk:"filename"`
  MergeType   types.String `tfsdk:"merge_type"`
}
```

### MIME Merge Types

| Merge Type | Behavior |
|-----------|----------|
| `list(append)` | Append lists |
| `list(merge)` | Merge lists (deduplicate) |
| `list(no_replace)` | Don't replace existing lists |
| `dict(recurse)` | Deep-merge dictionaries |
| `dict(no_replace)` | Don't replace existing dict keys |
| `str(append)` | Append strings |
| `str(no_replace)` | Don't replace strings |

### Rendering Pipeline

```go
func renderPartsToWriter(parts []configPartModel, boundary string, writer io.Writer) error {
  // 1. Create multipart writer with boundary
  mw := multipart.NewWriter(writer)
  mw.SetBoundary(boundary)

  for _, part := range parts {
    // 2. Create part header
    h := make(textproto.MIMEHeader)
    h.Set("Content-Type", part.ContentType.ValueString())
    h.Set("Content-Disposition",
      fmt.Sprintf("attachment; filename=\"%s\"", part.FileName.ValueString()))

    // 3. Write part
    pw, err := mw.CreatePart(h)
    if err != nil {
      return err
    }
    _, err = pw.Write([]byte(part.Content.ValueString()))
    if err != nil {
      return err
    }
  }

  // 4. Close multipart writer (writes final boundary)
  return mw.Close()
}
```

## Post-Processing

### Gzip Compression

```go
func applyGzip(data []byte) ([]byte, error) {
  var buf bytes.Buffer
  gw := gzip.NewWriter(&buf)
  if _, err := gw.Write(data); err != nil {
    return nil, err
  }
  if err := gw.Close(); err != nil {
    return nil, err
  }
  return buf.Bytes(), nil
}
```

### Base64 Encoding

```go
func applyBase64(data []byte) string {
  return base64.StdEncoding.EncodeToString(data)
}
```

### Processing Order

```go
func update(config *configModel) error {
  // 1. Render multipart MIME
  rendered := renderParts(config.Parts, config.Boundary)

  // 2. Compress if gzip enabled
  if config.Gzip.ValueBool() {
    rendered, _ = applyGzip([]byte(rendered))
  }

  // 3. Encode if base64 enabled
  if config.Base64Encode.ValueBool() {
    config.Rendered = types.StringValue(applyBase64(rendered))
  } else {
    config.Rendered = types.StringValue(string(rendered))
  }

  // 4. Generate ID (CRC-32 checksum of rendered content)
  config.ID = types.StringValue(fmt.Sprintf("%08x", crc32.ChecksumIEEE([]byte(config.Rendered.ValueString()))))

  return nil
}
```
