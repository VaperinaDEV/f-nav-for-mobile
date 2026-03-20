import { apiInitializer } from "discourse/lib/api";
import AvatarProfile from "../components/avatar-menu/profile";

export default apiInitializer("1.8.0", (api) => {
  api.headerIcons.add("avatar", AvatarProfile, { before: "user-menu" });
});
