local file = app.params["file"]

if not file or file == "" then
  error("Missing file")
end

app.open(file)
app.command.PlayAnimation()
