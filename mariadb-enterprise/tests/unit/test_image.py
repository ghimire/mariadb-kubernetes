import yaml
import os
import copy
import itertools


def flattenDict(args):
    result = {}
    for k, v in args.items():
        if isinstance(v, dict):
            for k1, v1 in flattenDict(v).items():
                result["{}.{}".format(k, k1)] = v1
        else:
            result["{}".format(k)] = v
    return result


def runHelm(args):
    cmdLine = "helm template ../.. --name=test"
    for k, v in flattenDict(args).items():
        cmdLine = cmdLine + " --set {}={}".format(k, v)

    result = os.popen(cmdLine)
    return yaml.safe_load_all(result)


def getContainers(resources):
    result = []
    if isinstance(resources, dict):
        for k, v in resources.items():
            if k == "containers" or k == "initContainers":
                for c in v:
                    result.append(c)
            elif isinstance(v, dict):
                result.extend(getContainers(v))
    else:
        for v in resources:
            result.extend(getContainers(v))

    return result


def supportedTopologies():
    return ["standalone", "masterslave", "galera",
            "columnstore-standalone", "columnstore"]


def defaultImages():
    with open("../../values.yaml", "r") as stream:
        values = yaml.safe_load(stream)
        return {"server": values["mariadb"]["server"]["image"],
                "statestore": values["mariadb"]["statestore"]["image"],
                "maxscale": values["mariadb"]["maxscale"]["image"],
                "columnstore": values["mariadb"]["columnstore"]["image"]}


def testImages():
    return {"server": "mariadb/server:test",
            "statestore": "mariadb/statestore:test",
            "maxscale": "mariadb/maxscale:test",
            "columnstore": "mariadb/columnstore:test"}


def verifyImageConfiguration(topology, clusterRepo, customImages, customImageRepos):
    values = {"mariadb":
              {"cluster": {"topology": topology},
               "server": {},
               "statestore": {},
               "maxscale": {},
               "columnstore": {}}}

    expected = defaultImages()
    custom = testImages()

    if customImages is not None:
        for c in customImages:
            values["mariadb"][c]["image"] = custom[c]
            expected[c] = custom[c]

    if clusterRepo is not None:
        values["mariadb"]["cluster"]["imageRepo"] = clusterRepo
        expected = {k: clusterRepo + "/" + v for k, v in expected.items()}

    if customImageRepos is not None:
        for c in customImageRepos:
            values["mariadb"][c]["image"] = "images.io/repo/" + custom[c]
            expected[c] = "images.io/repo/" + custom[c]

    tiDefaults = topologyImageDefaults()[topology]
    for c in getContainers(runHelm(values)):
        img = tiDefaults[c["name"]]
        print("Verifying image for container {} is {}".format(c['name'], img))
        try:
            assert expected[img] == c["image"]
        except AssertionError as error:
            print("Expected: {}, Actual: {}".format(expected[img], c["image"]))
            raise error

    return


def topologyImageDefaults():
    return {"standalone":
            {"mariadb-server": "server",
             "init-masterslave": "server",
             "init-get-master": "server"},
            "masterslave":
            {"state": "statestore",
             "state-store": "statestore",
             "mariadb-server": "server",
             "maxscale": "maxscale",
             "init-maxscale": "server",
             "init-get-master": "statestore",
             "init-masterslave": "server"},
            "galera":
            {"state": "statestore",
             "mariadb-server": "server",
             "maxscale": "maxscale",
             "init-maxscale": "server",
             "init-galera": "server",
             "state-store": "statestore",
             "init-get-galera": "statestore"},
            "columnstore":
            {"columnstore-module-um": "columnstore",
             "state-client": "statestore",
             "init-columnstore-pm": "columnstore",
             "state-store": "statestore",
             "init-volume": "columnstore",
             "init-columnstore-um": "columnstore",
             "init-get-um-master": "statestore",
             "columnstore-module-pm": "columnstore"},
            "columnstore-standalone":
            {"init-volume": "columnstore",
             "columnstore-module-pm": "columnstore",
             "init-columnstore": "columnstore"}}


def combinations(iterable):
    for n in range(len(iterable)+1):
        for cmb in itertools.combinations(iterable, n):
            yield cmb


def generateAllCombinations():
    imgKeys = set(testImages().keys())
    for repo in [None, "cluster.io/repo"]:
        for cmb in combinations(imgKeys):
            for cmb2 in combinations(imgKeys.difference(set(cmb))):
                yield repo, cmb, cmb2


def test_imageCombinations():
    print("Testing defaults")
    for t in supportedTopologies():
        for clusterRepo, clusterImages, clusterImagesRepo in generateAllCombinations():
            fmt = "Testing topology {} with repo {}, custom images {}, and custom images in repo {}"
            print(fmt.format(t, clusterRepo, clusterImages, clusterImagesRepo))
            verifyImageConfiguration(t, clusterRepo, clusterImages, clusterImagesRepo)
            print("--------------------------------------------------------")

if __name__ == "__main__" :
    print("Running tests from command line")
    test_imageCombinations()
