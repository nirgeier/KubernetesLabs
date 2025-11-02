#!/bin/bash

# Get the current folder when the script is executed from 
BASEDIR=$(dirname "$0")

# Switch to the base folder
echo $BASEDIR

# Load the colors
source ../../_utils/common.sh

# Get the root folder of our demo folder
ROOT_FOLDER=$(git rev-parse --show-toplevel)

# remove old content
rm    -rf ${ROOT_FOLDER}/roles_demo
mkdir ${ROOT_FOLDER}/roles_demo
cd    ${ROOT_FOLDER}/roles_demo

echo -e "${YELLOW}Initilaizing the role${COLOR_OFF}"
echo -e "${White}$ ${GREEN}ansible-galaxy init codewizard_lab_role${COLOR_OFF}"
ansible-galaxy init codewizard_lab_role

echo -e "${YELLOW}Switching to the role folder${COLOR_OFF}"
cd codewizard_lab_role

echo -e "${YELLOW}Creating content${COLOR_OFF}"

echo -e "${GREEN}* Generating defaults/main.yml${COLOR_OFF}"
cat << 'EOF' > defaults/main.yml
---
###
### This file contain the variables for the Demo lab
###

# Defaults file for codewizard_lab_role
motd_message: "Welcome to CodeWizard Ansible Roles Lab"

### The package we wish to install on the servers
apt_packages:
  - python3
  - nodejs
  - npm

# Packages to verify that they were installed
apt_packages_verify:
  - python3
  - npm

package_state: latest
EOF

echo -e "${GREEN}* Generating tasks/node-server.yml${COLOR_OFF}"
cat << 'EOF' > tasks/node-server.yml
---
- name: Copy Node server
  ansible.builtin.template:
    src: templates/node-server.j2
    dest: /node-server.js
    mode: 600
  become: true
  become_method: ansible.builtin.su

- name: Install "pm2" node.js package.
  community.general.npm:
    name: "pm2"
    global: true
  become: true
  become_method: ansible.builtin.su

- name: Get running node processes
  shell: "ps -ef | grep -v grep | grep -w node | awk '{print $2}'"
  register: running_processes

- name: Kill running node server (if any)
  shell: "kill {{ item }}"
  with_items: "{{ running_processes.stdout_lines }}"

- name: Wait for the process to die
  wait_for:
    path: "/proc/{{ item }}/status"
    state: absent
  with_items: "{{ running_processes.stdout_lines }}"
  ignore_errors: true
  register: killed_processes

- name: Force kill stuck processes
  shell: "kill -9 {{ item }}"
  with_items: "{{ killed_processes.results | select('failed') | map(attribute='item') | list }}"

- name: Start Node server
  ansible.builtin.command:
    chdir: /
    cmd: "pm2 start -f /node-server.js"
  register: server_status
  changed_when: server_status.rc != 0

- name: Print server status
  ansible.builtin.debug:
    msg: "{{ server_status.stdout_lines }}"
  when: server_status.rc == 0

- name: Check server
  uri:
    url: http://localhost:5000
    method: GET
    status_code: 200
  register: server_status

- name: Print server status
  ansible.builtin.debug:
    msg: "{{ server_status.status }} - {{ server_status.msg }}"
EOF

echo -e "${GREEN}* Generating tasks/motd.yml${COLOR_OFF}"
cat << 'EOF' > tasks/motd.yml
- name: Copy template
  ansible.builtin.template:
    src: templates/motd.j2
    dest: /etc/motd
    mode: preserve
  become: true
  become_method: ansible.builtin.su
EOF

echo -e "${GREEN}* Generating tasks/main.yml${COLOR_OFF}"
cat << 'EOF' > tasks/main.yml
---
- name: Include Pre-Requirements task
  ansible.builtin.include_tasks:
    file: pre-requirements.yaml

- name: Include motd task
  ansible.builtin.include_tasks:
    file: motd.yaml

- name: Deploy node server
  ansible.builtin.include_tasks:
    file: node-server.yaml
EOF

echo -e "${GREEN}* Generating tasks/pre-requirements.yml${COLOR_OFF}"
cat << 'EOF' > tasks/pre-requirements.yml
---
- name: Install Packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: "{{ package_state }}"
  # Loop over the required packages to install
  with_items: "{{ apt_packages }}"

- name: Verify Packages Installation
  ansible.builtin.command: "{{ item }} --version"
  register: packages_version
  with_items: "{{ apt_packages_verify }}"

- name: Print package version
  ansible.builtin.debug:
    msg: "{{ item.stdout_lines }}"
  with_items: "{{ packages_version.results }}"
EOF  

echo -e "${GREEN}* Generating templates/motd.j2${COLOR_OFF}"
cat << 'EOF' > templates/motd.j2
_____             _          _    _  _                      _ 
/  __ \           | |        | |  | |(_)                    | |
| /  \/  ___    __| |  ___   | |  | | _  ____ __ _  _ __  __| |
| |     / _ \  / _` | / _ \  | |/\| || ||_  // _` || '__|/ _` |
| \__/\| (_) || (_| ||  __/  \  /\  /| | / /| (_| || |  | (_| |
 \____/ \___/  \__,_| \___|   \/  \/ |_|/___|\__,_||_|   \__,_|
 
{{ motd_message }}

System information:
-------------------

OS:         {{ ansible_distribution }} {{ ansible_distribution_version }}
Hostname:   {{ inventory_hostname }}

{{ custom_message | default('') }}
EOF

echo -e "${GREEN}* Generating templates/node-server.j2${COLOR_OFF}"
cat << 'EOF' > templates/node-server.j2
const
  // Set the server port which will be listening to
  // Those 2 values are passed from the env file
  SERVER_PORT = 5000,
  SERVER_NAME = "{{ inventory_hostname }}";

  // Create the basic http server
  require('http')
    .createServer((request, response) => {

        // Send reply to user
        response.end(`<h1>Hello from ${SERVER_NAME}.</h1>`);

    }).listen(SERVER_PORT, () => {
        // Notify users that the server is up and running
        console.log(`${SERVER_NAME} is up. 
            Please click or point your browser to:
            http://localhost:${SERVER_PORT}`);
    });
EOF

echo -e "${GREEN}* Generating 009-role-playbook.yml${COLOR_OFF}"
cat << 'EOF' > 009-role-playbook.yml
---
###
### The playbook for using our role
### 
- name: Executing codewizard_lab_role
  hosts: all
  become: true
  become_method: ansible.builtin.su

  roles:
    - codewizard_lab_role
EOF 

echo -e "${YELLOW}Verifying role creation${COLOR_OFF}"
tree -a codewizard_lab_role

