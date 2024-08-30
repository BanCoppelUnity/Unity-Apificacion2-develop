import os
import shutil
import pytest
import tftest
from pathlib import Path

params = {
    "profile": "devsecops",
    "ami_owners": "356620620364"
}

files = ["variables.tf", "outputs.tf", "dev-vars.tfvars", "init_script.sh"]

values = [
    "data.terraform_remote_state.networking_state.outputs.security_groups_id", 
    "data.terraform_remote_state.networking_state.outputs.subnets_id",
    "policies/"
    ]

modified_values = [
    "local.security_groups_config",
	"local.subnet_config",
    ""
    ]

file_paths = [Path("..") / file for file in files]

normalized_paths = [str(path.resolve()) for path in file_paths]

def extra_files(path):
    with os.scandir(path) as files:
        extra_files = [file.name for file in files if file.is_file()]
    return  [Path(path) / file for file in extra_files]

def copy_file(path_origin, path_destiny):
    shutil.copy2(path_origin, path_destiny)

def modify_file(file_path, values, modified_values):
    with open(file_path, 'r') as file:
        content = file.read()
    for value, modified_value in zip(values, modified_values):
        content = content.replace(value, modified_value)
    with open(file_path, 'w') as file:
        file.write(content)

def remove_file(file):
    os.remove(file)


@pytest.fixture
def output():
    normalized_paths.extend(extra_files('../policies'))
    copy_file("../main.tf", "unit")
    modify_file("unit/main.tf", values, modified_values)
    tf = tftest.TerraformTest("unit")
    tf.setup(extra_files=normalized_paths , workspace_name="test")
    tf.apply(tf_vars=params, tf_var_file="dev-vars.tfvars")
    yield tf.output()
    tf.destroy(tf_vars=params, tf_var_file="dev-vars.tfvars", **{"auto_approve": True})
    remove_file("unit/main.tf")

def test(output):
    assert output['aws_region'] == "us-east-1"
    for ip in output['expected_public_ips'] :
        assert ip == ""