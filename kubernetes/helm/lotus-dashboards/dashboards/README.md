## Saving a dashboard to git, for all to enjoy.
1. Tag your dashboard with the `lotus` tag.
	- If you have additional useful tags, you can add those as well.
2. Run the dashboard code (in this directory)
```bash
$ export GRAFANA_API_KEY="XXX" 
$ go run main.go
```
or
```bash
$ go run main.go -apikey "XXX"
```


## Import dashboards to your grafana instance
(same as saving, but adding the -import flag)

```bash
$ export GRAFANA_API_KEY="XXX"
$ go run main.go -import
```
or
```bash
$ go run main.go -apikey "XXX" -import
```
