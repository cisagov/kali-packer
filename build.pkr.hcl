build {
  sources = [
    # There is no ARM-based official Kali AMI in the AWS AMI Catalog.
    # "source.amazon-ebs.arm64",
    "source.amazon-ebs.x86_64",
  ]

  provisioner "ansible" {
    galaxy_file            = "ansible/requirements.yml"
    galaxy_force_install   = var.force_install_ansible_requirements
    galaxy_force_with_deps = var.force_install_ansible_requirements_with_dependencies
    playbook_file          = "ansible/upgrade.yml"
    use_proxy              = false
    use_sftp               = true
  }

  provisioner "ansible" {
    playbook_file = "ansible/python.yml"
    use_proxy     = false
    use_sftp      = true
  }

  provisioner "ansible" {
    ansible_env_vars = ["AWS_DEFAULT_REGION=${var.build_region}"]
    extra_arguments  = ["--extra-vars", "{build_bucket: ${var.build_bucket}}"]
    playbook_file    = "ansible/playbook.yml"
    use_proxy        = false
    use_sftp         = true
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; sudo env {{ .Vars }} {{ .Path }} ; rm -f {{ .Path }}"
    inline          = ["sed -i '/^users:/ {N; s/users:.*/users: []/g}' /etc/cloud/cloud.cfg", "rm --force /etc/sudoers.d/90-cloud-init-users", "rm --force /root/.ssh/authorized_keys", "/usr/sbin/userdel --remove --force kali"]
    skip_clean      = true
  }
}
