from pulumi import automation

from .lib.variables import variables as var


def pulumi_program():
    from .lib.github_actions import example, pool, workload_identity_user  # noqa: F401
    from .lib.iam import sa_iam_cicd, sa_iam_dbt  # noqa: F401
    from .lib.service_account import dbt_sa, github_actions_sa  # noqa: F401


def set_plugins(stack: automation.Stack) -> None:
    stack.workspace.install_plugin("gcp", "v6.46.0")


def set_config(stack: automation.Stack) -> None:
    stack.set_config("gcp:project", automation.ConfigValue(value=var.project))
    stack.set_config("gcp:region", automation.ConfigValue(value=var.region))
    stack.set_config("gcp:zone", automation.ConfigValue(value=var.zone))


def main():
    stack = automation.create_or_select_stack(
        stack_name=var.stack_name, project_name=var.project_name, program=pulumi_program
    )
    # set_plugins(stack)
    set_config(stack)
    # stack.refresh(on_output=print, color="always")
    stack.up(diff=True, color="always", on_output=print)
    # stack.destroy(on_output=print)


if __name__ == "__main__":
    main()
