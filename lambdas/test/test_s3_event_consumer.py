import unittest
# importing sys
import sys

sys.path.insert(0, '../../lambdas')
import s3_event_consumer


class S3EventConsumer(unittest.TestCase):

    def setUp(self) -> None:
        self.event = {
            "Records": [
                {
                    "eventVersion": "2.1",
                    "eventSource": "aws:s3",
                    "awsRegion": "eu-west-1",
                    "eventTime": "2022-02-06T06:52:50.300Z",
                    "eventName": "ObjectCreated:Put",
                    "userIdentity": {
                        "principalId": "AWS:AROAT3WP3AWLWJN3D7ERZ:shohag@m2amedia.tv"
                    },
                    "requestParameters": {
                        "sourceIPAddress": "103.136.1.53"
                    },
                    "responseElements": {
                        "x-amz-request-id": "7FHP6T5TE0YTVHXG",
                        "x-amz-id-2": "U298gEfrLUGeAfRj9Ox7Aj++hIFYPmmHWDoH+QsLHBG2uxce"
                                      "+9Xr2lM1vIZQPTnfCg25Qp7DyzJPEEmwx5UviZa/2w4ZH2D6 "
                    },
                    "s3": {
                        "s3SchemaVersion": "1.0",
                        "configurationId": "tf-s3-lambda-20220206061149286800000001",
                        "bucket": {
                            "name": "shohag-onboarding-test-bucket",
                            "ownerIdentity": {
                                "principalId": "AIZZN1RJ03R2Q"
                            },
                            "arn": "arn:aws:s3:::shohag-onboarding-test-bucket"
                        },
                        "object": {
                            "key": "ProfilePicturePhoto.jpg",
                            "size": 155984,
                            "eTag": "c27c7fd5b21cbb17fb68f2f45d45ac59",
                            "sequencer": "0061FF704242919E0D"
                        }
                    }
                }
            ]
        }
        self.s3_objects = [{
            "key": "ProfilePicturePhoto.jpg",
            "size": 155984,
            "eTag": "c27c7fd5b21cbb17fb68f2f45d45ac59",
            "sequencer": "0061FF704242919E0D"
        }]

    def test_event_parser(self):
        objects = s3_event_consumer.event_parser(self.event)
        self.assertEqual(len(objects), 1)
        self.assertEqual(objects, self.s3_objects)
        with self.assertRaises(ValueError):
            s3_event_consumer.event_parser({})


if __name__ == "__main__":
    unittest.main()
