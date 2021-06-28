#!/usr/bin/env python3

import glob
import os
import shutil
import subprocess


def fuzz(test, seed, duration, json=False):
    if os.path.exists("./test_output"):
        shutil.rmtree("./test_output")
    os.mkdir("./test_output")

    subprocess.run(
        [
            "timeout",
            duration,
            "../fuzzer",
            "-store_passing_input",
            test,
            seed,
            "./test_output",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    crashes = os.listdir("./test_output/crash")

    if not json:
        return len(crashes)

    coverage_set = set()
    unique_crash_set = set()

    for crash in crashes:
        path = os.path.join("./test_output/crash", crash)
        result = subprocess.Popen(
            [test],
            stdin=open(path, "rb"),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        result = result.stdout.read().decode()

        with open(test + ".cov", "r") as f:
            coverage_set.update(f.read().strip().split("\n"))
        unique_crash_set.update(result.strip().split("\n"))

    passes = os.listdir("./test_output/pass")
    for pass_ in passes:
        path = os.path.join("./test_output/pass", pass_)
        result = subprocess.Popen(
            [test],
            stdin=open(path, "rb"),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
        )
        result = result.stdout.read().decode()

        with open(test + ".cov", "r") as f:
            coverage_set.update(f.read().strip().split("\n"))

    return len(crashes), len(coverage_set), len(unique_crash_set)


if __name__ == "__main__":
    # 1. Simple + Advanced
    simple = glob.glob("./simple/*.c")
    advanced = glob.glob("./advanced/*.c")
    tests = list(map(lambda x: x.replace(".c", ""), simple + advanced))

    passed, total = 0, 0
    for test in tests:
        if "runtime" in test:
            continue
        total += 1

        num_crash = fuzz(test, "./test_seed", "1m")
        if num_crash:
            print("Test {} Passed".format(test))
            passed += 1
        else:
            print("Test {} Failed".format(test))

    print("Total Score: {} / {}".format(passed, total))

    # 2. JSON
    num_crash, num_cov, num_unique_crash = fuzz(
        "./json_parser", "./json_seed", "20m", True
    )

    print("JSON Coverage Score: {} / 800".format(num_cov))
    print("JSON Unique Crash Score: {} / 12".format(num_unique_crash))
