#!/usr/local/bin/python3

import aws_lambda_ec2_schedule as s
import unittest

class TestAwsLambdaEc2Schedule(unittest.TestCase):
    def test_to_unixtimestamp(self):
        self.assertEqual(s.to_unixtimestamp('00:00'), -2208988800)
        self.assertEqual(s.to_unixtimestamp('10:00'), -2208952800)

    def test_in_schedule(self):
        # Fuera de hora por encima:
        self.assertEqual(s.out_of_time('12:00', '10:00', '11:00'), True)
        # Dentro de la hora:
        self.assertEqual(s.out_of_time('12:00', '10:00', '18:00'), False)
        # Fuera de hora por debajo:
        self.assertEqual(s.out_of_time('12:00', '14:00', '18:00'), True)
        # Todas las horas iguales:
        self.assertEqual(s.out_of_time('12:00', '12:00', '12:00'), False)
        # Igual que la hora de salida:
        self.assertEqual(s.out_of_time('12:00', '11:00', '12:00'), False)
        # Igual que la hora de entrada:
        self.assertEqual(s.out_of_time('12:00', '12:00', '13:00'), True)
        # Fuera de hora del día siguiente:
        self.assertEqual(s.out_of_time('02:00', '10:00', '01:00'), True)

    def test_is_valid_workdays(self):
        self.assertEqual(s.is_valid_workdays('UUUUUUU'), 'U')
        self.assertEqual(s.is_valid_workdays('SSSSSSS'), 'S')
        self.assertEqual(s.is_valid_workdays('sssssss'), 'S')
        self.assertEqual(s.is_valid_workdays('DDDDDDD'), 'D')
        self.assertEqual(s.is_valid_workdays('ssssss'), False)
        self.assertEqual(s.is_valid_workdays('ssssssss'), False)
        self.assertEqual(s.is_valid_workdays('abcdefg'), False)

if __name__ == '__main__':
    unittest.main()
