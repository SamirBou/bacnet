from app.objects.secondclass.c_fact import Fact
from app.objects.secondclass.c_relationship import Relationship
from app.utility.base_parser import BaseParser
import re


WHOIS_TABLE_RE = re.compile(r'^\s*(\d+)\s+([0-9A-Fa-f:]+)')


class Parser(BaseParser):
    def parse(self, blob):
        relationships = []
        for line in self.line(blob):
            m = WHOIS_TABLE_RE.match(line.strip())
            if not m:
                continue
            
            device_instance = m.group(1)
            
            for mp in self.mappers:
                source = self.set_value(mp.source, device_instance, self.used_facts)
                target = self.set_value(mp.target, device_instance, self.used_facts)
                relationships.append(
                    Relationship(
                        source=Fact(mp.source, source),
                        edge=mp.edge,
                        target=Fact(mp.target, target)
                    )
                )
        return relationships
