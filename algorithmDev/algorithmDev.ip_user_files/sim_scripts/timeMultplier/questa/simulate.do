onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib timeMultplier_opt

do {wave.do}

view wave
view structure
view signals

do {timeMultplier.udo}

run -all

quit -force
