#!/bin/bash
bright_value=${1:-45}
ddcutil --bus 14 setvcp 10 $bright_value
