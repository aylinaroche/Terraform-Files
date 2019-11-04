data "template_file" "kubeconfig" {
  template = "${file("${path.module}/templates/kubeconfig.tpl")}"
}

resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "${path.module}/tmp/kubeconfig"
}

data "local_file" "dashboard" {
  filename = "${path.module}/kubernetes-dashboard.yaml"
}

resource "null_resource" "get-contexts" {
  provisioner "local-exec" {
    command = "kubectl config get-contexts"
  }
}

resource "null_resource" "dashboard_exec" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${data.local_file.dashboard.filename} --kubeconfig ${local_file.kubeconfig.filename}"
  }
}

