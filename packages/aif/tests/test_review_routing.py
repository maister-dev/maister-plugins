"""Review routing examples must remain self-contained and match shipped schemas.

Run: python3 -m unittest discover -s packages/aif/tests -v (requires PyYAML).
This intentionally reads each node prompt without loading any installed skill:
projects may carry older local skills, which take precedence over package skills.
"""
import json
from pathlib import Path
import re
import unittest

import yaml

PACKAGE = Path(__file__).resolve().parents[1]


class ReviewRoutingContract(unittest.TestCase):
    def test_review_examples_match_declared_contract_without_skill_context(self):
        reviewed = set()
        for path in sorted((PACKAGE / "flows").glob("*/flow.yaml")):
            flow = yaml.safe_load(path.read_text())
            for node in flow["nodes"]:
                if node.get("decide", {}).get("from") != "output.recommendation":
                    continue
                with self.subTest(flow=flow["name"], node=node["id"]):
                    reviewed.add((flow["name"], node["id"]))
                    schema = json.loads((PACKAGE / node["output"]["result"]["schema"]).read_text())
                    prompt = node["action"]["prompt"]
                    examples = re.findall(r"```json maister:output\n(.*?)\n```", prompt, re.S)
                    self.assertEqual(len(examples), 1, "routing must not depend on local skill content")
                    example = json.loads(examples[0])
                    for field in schema["fields"]:
                        if field.get("required"):
                            self.assertIn(field["name"], example)
                        if field["name"] in example and field["type"] == "enum":
                            self.assertIn(example[field["name"]], field["options"])
                        if field["name"] in example and field["type"] == "string":
                            self.assertIsInstance(example[field["name"]], str)
                    self.assertNotIn("status", example)
                    self.assertIn('Set recommendation to "fix"', prompt)
                    self.assertIn('or "commit"', prompt)
                    self.assertIn('NOT `status`', prompt)
                    self.assertEqual(set(node["transitions"]) - {"exhausted"}, {"fix", "commit"})
        self.assertEqual(reviewed, {
            ("aif-dev", "code_review"), ("aif-dev", "cross_review"),
            ("aif-dev-light", "code_review"),
            ("aif-autonomous", "code_review"), ("aif-autonomous", "cross_review"),
            ("aif-bugfix", "code_review"), ("aif-bugfix", "cross_review"),
        })


if __name__ == "__main__":
    unittest.main()
