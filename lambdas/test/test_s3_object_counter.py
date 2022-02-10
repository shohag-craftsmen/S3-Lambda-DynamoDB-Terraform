import unittest
# importing sys
import sys

sys.path.insert(0, '../../lambdas')
import s3_object_counter


class S3ObjectCounter(unittest.TestCase):

    def setUp(self) -> None:
        self.s3_objects = [{
            "key": "ProfilePicturePhoto.jpg",
            "size": 155984,
            "eTag": "c27c7fd5b21cbb17fb68f2f45d45ac59",
            "sequencer": "0061FF704242919E0D"
        }]
        self.parser_result = {
            "jpg": 1
        }

    def test_event_parser(self):
        s3_object_count_map = s3_object_counter.event_parser(self.s3_objects)
        self.assertEqual(len(s3_object_count_map.items()), 1)
        self.assertEqual(s3_object_count_map, self.parser_result)
        empty_result = s3_object_counter.event_parser([])
        self.assertEqual(len(empty_result.items()), 0)


if __name__ == "__main__":
    unittest.main()
