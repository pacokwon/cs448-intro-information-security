results/%.result: main.py
	@mkdir -p results
	@awk '{print $$1 " " $$2}' ./ciphertexts/ciphertext_$*.txt | xargs python main.py > results/$*.result

test%: results/%.result
	diff results/$*.result ./ciphertexts/plaintext_$*.txt

server:
	java -cp pad_oracle.jar:bcprov-jdk15-130.jar:python_interface_v1_2.jar python_interface_v1_2

clean:
	rm -rf results

.PRECIOUS: results/%.result
.PHONY: test% server clean
