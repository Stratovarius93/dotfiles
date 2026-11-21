import os
from ranger.api.commands import Command


class quit_cd(Command):
    """Cierra ranger y guarda la carpeta actual para que zsh haga cd."""

    def execute(self):
        cd_file = os.environ.get("RANGER_CD_FILE")
        if cd_file:
            with open(cd_file, "w", encoding="utf-8") as f:
                f.write(self.fm.thisdir.path)
        self.fm.execute_console("quit")
