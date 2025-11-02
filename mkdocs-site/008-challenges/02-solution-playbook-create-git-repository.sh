---
- hosts: linux-server-2
  gather_facts: no
  tasks:
    - name: Ensure git is installed
      apt:
        name: git
        state: present
      become: yes

    - name: Clone the repository
      git:
        repo: https://github.com/yourusername/yourrepository.git
        dest: /tmp/ansible-git-demo
        clone: yes
        update: yes

    - name: Commit and push changes
      shell: |
        cd /tmp/ansible-git-demo
        git config --global user.email "nirgeier@gmail.com"
        git config --global user.name "Nir Geier"
        git add .
        git commit -m "Your commit message"
        git push origin main
      args:
        executable: /bin/bash
