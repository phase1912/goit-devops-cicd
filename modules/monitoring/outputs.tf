output "grafana_port_forward" {
  value = "kubectl port-forward svc/grafana 3000:80 -n ${var.namespace}"
}
