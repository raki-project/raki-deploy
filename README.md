[1]: https://github.com/dice-group/RAKI-Drill-Endpoint

# Clone and Deploy
<!---
## Build the DRILL Docker image

Follow  the documentation in
[Drill][1] and name the image `drill`.

## Build the Verbalizer Docker image

Run: `docker build -t raki-webapp:latest "."`.

# Start
-->
```bash
git clone --recurse-submodules https://github.com/raki-project/raki-deploy.git && cd raki-deploy/drill && unzip LPs.zip && cd ..
docker-compose build

```

<!---
`git submodule update --init --recursive`
-->

# Start
Start the application by running:
```bash
docker-compose up
```
# GUI

Open in your browser: http://localhost:9081/

# Example Request

A request has two parameters.
One with an input file (e.g., `input.json`) that contains an input for Drill as described in [Drill][1]
and another parameter with a file (e.g., `biopax.owl`) that contains an ontology.

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

By default the rule-based version is used. The parameter `type` with the value `model` will use the trained network in the beta version (e.g., `http://localhost:9081/raki?type=model`).  
