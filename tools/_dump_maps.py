# -*- coding: utf-8 -*-
import mockup_campaign as m
for nm in ['FOREST', 'CITY']:
    print('=== ' + nm + ' ===')
    for row in m._norm(getattr(m, nm)):
        print('\t\t"' + row + '",')
