terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

variable "YA_TOKEN" {
  type = string
}

provider "yandex" {
  token     = var.YA_TOKEN
  cloud_id  = "cloud-ww-bel"
  folder_id = "b1g1ea8du0rjbjnjl075"
  zone      = "ru-central1-b"
}

resource "yandex_container_registry" "devops14" {
  name = "devops14"
}

resource "yandex_compute_instance" "vm-1" {
  name = "devops-edu-14-1"

  allow_stopping_for_update = true

  depends_on = [
    yandex_container_registry.devops14
  ]

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: wwbel\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("/Users/wwbel/.ssh/id_rsa.pub")}"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8qps171vp141hl7g9l" // Ubuntu 20.04
    }
  }
  network_interface {
    subnet_id = "e2lcrt85pcpnboln5af9"
    nat = true
  }
  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  connection {
    type     = "ssh"
    user     = "wwbel"
    private_key = "${file("/Users/wwbel/.ssh/id_rsa")}"
    host     = self.network_interface.0.nat_ip_address
  }

  provisioner "file" {
    source = "Dockerfile"
    destination = "Dockerfile"
  }

  provisioner "remote-exec" {
    inline = [
       "sudo apt update"
      ,"sudo apt install docker.io -y"
      ,"sudo docker build -t cr.yandex/${yandex_container_registry.devops14.id}/boxfuse ."
      ,"sudo docker login --username oauth --password ${var.YA_TOKEN} cr.yandex"
      ,"sudo docker push cr.yandex/${yandex_container_registry.devops14.id}/boxfuse"
    ]
  }

}


resource "yandex_compute_instance" "vm-2" {
  name = "devops-edu-14-2"

  allow_stopping_for_update = true

  depends_on = [
    yandex_container_registry.devops14,
    yandex_compute_instance.vm-1
  ]

  metadata = {
    user-data = "#cloud-config\nusers:\n  - name: wwbel\n    groups: sudo\n    shell: /bin/bash\n    sudo: ['ALL=(ALL) NOPASSWD:ALL']\n    ssh-authorized-keys:\n      - ${file("/Users/wwbel/.ssh/id_rsa.pub")}"
  }
  boot_disk {
    initialize_params {
      image_id = "fd8qps171vp141hl7g9l" // Ubuntu 20.04
    }
  }
  network_interface {
    subnet_id = "e2lcrt85pcpnboln5af9"
    nat = true
  }
  resources {
    cores  = 2
    memory = 2
  }

  scheduling_policy {
    preemptible = true
  }

  connection {
    type     = "ssh"
    user     = "wwbel"
    private_key = "${file("/Users/wwbel/.ssh/id_rsa")}"
    host     = self.network_interface.0.nat_ip_address
  }

  provisioner "remote-exec" {
    inline = [
       "sudo apt update"
      ,"sudo apt install docker.io -y"
      ,"sudo docker login --username oauth --password ${var.YA_TOKEN} cr.yandex"
      ,"sudo docker run -d -p \"8080:8080\" cr.yandex/${yandex_container_registry.devops14.id}/boxfuse"
    ]
  }
}

output "external_ip_address_vm_2" {
  value = yandex_compute_instance.vm-2.network_interface.0.nat_ip_address
}

