[1]: https://github.com/dice-group/RAKI-Drill-Endpoint

# RAKI Demo

## Deploy
Deploys the RAKI Demo with the Biopax data.
Read [deploy with your data](#deploy-with-your-data) to deploy the RAKI Demo with other data.

### Clone
Clones this repository to your local folder: `raki-deploy`.

```bash
git clone --recurse-submodules https://github.com/raki-project/raki-deploy.git
```

### Build
Builds your application in your local folder.

```bash
cd drill && unzip LPs.zip
sudo docker compose build

```

### Start
Starts your application:

```bash
sudo docker compose up
```

## Deploy with your Data
Update the `docker-compose.yml` file and add your data to the drill service build environment.

## Endpoints

###  /info
Send a HTTP GET request without parameters to get information about your application to http://localhost:9081/info.

### /raki
Send a HTTP POST request that requires two parameters to http://localhost:9081/raki

The two parameters are:
- `input` A JSON file that contains an input for Drill as described in [Drill][1],

- `ontology` A RDF/OWL file, an ontology.

By default the rule-based verbalizer is set.
The parameter `type` with the value `model` will switch to the trained network in the beta version (e.g., `http://localhost:9081/raki?type=model`).  

### /verbalize

Send a HTTP POST request that requires two parameters to http://localhost:9081/verbalize

The two parameters are:
- `axioms` A RDF/OWL file to verbalize.

- `ontology` A RDF/OWL file, an ontology.

## GUI
In your browser open http://localhost:9081/ to request the GUI.

## Example
An input can be created with, for instance:
```bash
jq '
   .problems
     ."((pathwayStep ⊓ (∀INTERACTION-TYPE.Thing)) ⊔ (sequenceInterval ⊓ (∀ID-VERSION.Thing)))"
   | {
      "positives": .positive_examples,
      "negatives": .negative_examples
     }' LPs/Biopax/lp.json > input.json

```
The files in the `LPs` folder are given in [Drill][1].

Request example with Curl:
```bash
ontology="@biopax.owl"
input="@input.json"
response=$0.json

curl \
	-F ontology=$ontology \
	-F input=$input \
	-H "charset=utf-8" \
	-o $response \
	http://localhost:9081/raki
```
